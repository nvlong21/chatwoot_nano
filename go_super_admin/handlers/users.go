package handlers

import (
	"crypto/md5"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"

	"chatwoot/go_super_admin/db"
	"chatwoot/go_super_admin/models"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

var StoragePath = "/storage"

func avatarBlobKey(userID int) (string, string, error) {
	var result struct {
		BlobKey     string
		ContentType string
	}
	err := db.DB.Raw(`
		SELECT asb.key AS blob_key, asb.content_type
		FROM active_storage_attachments asa
		JOIN active_storage_blobs asb ON asb.id = asa.blob_id
		WHERE asa.record_type = 'User' AND asa.record_id = ? AND asa.name = 'avatar'
		LIMIT 1`, userID).Scan(&result).Error
	if err != nil || result.BlobKey == "" {
		return "", "", fmt.Errorf("not found")
	}
	return result.BlobKey, result.ContentType, nil
}

func populateAvatarURL(users []models.User, host string) {
	if len(users) == 0 {
		return
	}
	ids := make([]int, len(users))
	for i, u := range users {
		ids[i] = u.ID
	}
	var rows []struct {
		RecordID int64
		BlobID   int64
	}
	db.DB.Raw(`
		SELECT asa.record_id, asa.blob_id
		FROM active_storage_attachments asa
		JOIN active_storage_blobs asb ON asb.id = asa.blob_id
		WHERE asa.record_type = 'User' AND asa.record_id IN ? AND asa.name = 'avatar'`, ids).Scan(&rows)
	blobByID := map[int64]int64{}
	for _, r := range rows {
		blobByID[r.RecordID] = r.BlobID
	}
	for i, u := range users {
		if blobID, ok := blobByID[int64(u.ID)]; ok {
			users[i].AvatarUrl = fmt.Sprintf("%s/super_admin/api/users/%d/avatar?v=%d", host, u.ID, blobID)
		}
	}
}

func UsersIndex(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	search := c.Query("search")
	pg := models.NewPagination(page, 25)

	query := db.DB.Model(&models.User{})
	if search != "" {
		if id, err := strconv.Atoi(search); err == nil {
			query = query.Where("id = ? OR name ILIKE ? OR email ILIKE ?", id, "%"+search+"%", "%"+search+"%")
		} else {
			query = query.Where("name ILIKE ? OR email ILIKE ?", "%"+search+"%", "%"+search+"%")
		}
	}
	query.Count(&pg.TotalCount)
	pg.SetTotal(pg.TotalCount)

	var users []models.User
	query.Offset(pg.Offset()).Limit(pg.PerPage).Order("id desc").Find(&users)
	populateAvatarURL(users, origin(c))
	c.JSON(http.StatusOK, gin.H{"data": users, "meta": pg})
}

func UsersShow(c *gin.Context) {
	user := findUser(c)
	if user == nil {
		return
	}
	users := []models.User{*user}
	populateAvatarURL(users, origin(c))
	user = &users[0]
	var accountUsers []models.AccountUser
	db.DB.Preload("Account").Where("user_id = ?", user.ID).Find(&accountUsers)
	c.JSON(http.StatusOK, gin.H{"user": user, "account_users": accountUsers})
}

func UsersAvatarServe(c *gin.Context) {
	id, _ := strconv.Atoi(c.Param("id"))
	key, contentType, err := avatarBlobKey(id)
	if err != nil {
		c.Status(http.StatusNotFound)
		return
	}
	if contentType == "" {
		contentType = "image/jpeg"
	}
	path := filepath.Join(StoragePath, key[0:2], key[2:4], key)
	c.Header("Content-Type", contentType)
	c.Header("Cache-Control", "public, max-age=3600")
	c.File(path)
}

func UsersAvatarUpload(c *gin.Context) {
	id, _ := strconv.Atoi(c.Param("id"))
	user := &models.User{}
	if err := db.DB.First(user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}

	file, header, err := c.Request.FormFile("avatar")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "avatar file required"})
		return
	}
	defer file.Close()

	data, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to read file"})
		return
	}

	// Generate random key (similar to Rails SecureRandom.base58)
	keyBytes := make([]byte, 24)
	rand.Read(keyBytes)
	key := base64.RawURLEncoding.EncodeToString(keyBytes)

	// Calculate MD5 checksum (base64 encoded, as Rails does)
	sum := md5.Sum(data)
	checksum := base64.StdEncoding.EncodeToString(sum[:])

	// Write file to disk
	dir := filepath.Join(StoragePath, key[0:2], key[2:4])
	if err := os.MkdirAll(dir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "storage error"})
		return
	}
	if err := os.WriteFile(filepath.Join(dir, key), data, 0644); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "write error"})
		return
	}

	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "image/jpeg"
	}

	// Create blob record
	serviceName := os.Getenv("ACTIVE_STORAGE_SERVICE")
	if serviceName == "" {
		serviceName = "local"
	}
	blob := models.ActiveStorageBlob{
		Key: key, Filename: header.Filename, ContentType: contentType,
		Checksum: checksum, ByteSize: int64(len(data)), ServiceName: serviceName,
	}
	if err := db.DB.Create(&blob).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "db error"})
		return
	}

	// Upsert attachment (delete old, create new)
	db.DB.Where("record_type = 'User' AND record_id = ? AND name = 'avatar'", id).Delete(&models.ActiveStorageAttachment{})
	attachment := models.ActiveStorageAttachment{
		Name: "avatar", RecordType: "User", RecordID: int64(id), BlobID: blob.ID,
	}
	db.DB.Create(&attachment)

	avatarUrl := fmt.Sprintf("%s/super_admin/api/users/%d/avatar?v=%d", origin(c), id, blob.ID)
	c.JSON(http.StatusOK, gin.H{"avatar_url": avatarUrl})
}

func origin(c *gin.Context) string {
	scheme := "http"
	if c.Request.TLS != nil {
		scheme = "https"
	}
	return scheme + "://" + c.Request.Host
}

func UsersCreate(c *gin.Context) {
	var input struct {
		Name        string `json:"name" binding:"required"`
		DisplayName string `json:"display_name"`
		Email       string `json:"email" binding:"required,email"`
		Password    string `json:"password" binding:"required,min=6"`
		Type        string `json:"type"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not hash password"})
		return
	}
	userType := input.Type
	if userType == "" {
		userType = "User"
	}
	user := models.User{
		Name: input.Name, DisplayName: input.DisplayName,
		Email: input.Email, EncryptedPassword: string(hash), Type: userType,
	}
	if err := db.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, user)
}

func UsersUpdate(c *gin.Context) {
	user := findUser(c)
	if user == nil {
		return
	}
	var input struct {
		Name        string `json:"name"`
		DisplayName string `json:"display_name"`
		Email       string `json:"email"`
		Password    string `json:"password"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if input.Name != "" {
		user.Name = input.Name
	}
	if input.DisplayName != "" {
		user.DisplayName = input.DisplayName
	}
	if input.Email != "" {
		user.Email = input.Email
	}
	if input.Password != "" {
		hash, _ := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
		user.EncryptedPassword = string(hash)
	}
	db.DB.Save(user)
	c.JSON(http.StatusOK, user)
}

func UsersDestroy(c *gin.Context) {
	user := findUser(c)
	if user == nil {
		return
	}
	db.DB.Delete(user)
	c.JSON(http.StatusOK, gin.H{"message": "deleted"})
}

func findUser(c *gin.Context) *models.User {
	var user models.User
	if err := db.DB.First(&user, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return nil
	}
	return &user
}
