package handlers

import (
	"net/http"
	"strconv"

	"chatwoot/go_super_admin/db"
	"chatwoot/go_super_admin/models"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

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
	c.JSON(http.StatusOK, gin.H{"data": users, "meta": pg})
}

func UsersShow(c *gin.Context) {
	user := findUser(c)
	if user == nil {
		return
	}
	var accountUsers []models.AccountUser
	db.DB.Preload("Account").Where("user_id = ?", user.ID).Find(&accountUsers)
	c.JSON(http.StatusOK, gin.H{"user": user, "account_users": accountUsers})
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
