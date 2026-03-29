package handlers

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"chatwoot/go_super_admin/db"
	"chatwoot/go_super_admin/models"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

func AccountsIndex(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	search := c.Query("search")
	pg := models.NewPagination(page, 25)

	query := db.DB.Model(&models.Account{})
	if search != "" {
		if id, err := strconv.Atoi(search); err == nil {
			query = query.Where("id = ? OR name ILIKE ?", id, "%"+search+"%")
		} else {
			query = query.Where("name ILIKE ?", "%"+search+"%")
		}
	}
	query.Count(&pg.TotalCount)
	pg.SetTotal(pg.TotalCount)

	var accounts []models.Account
	query.Offset(pg.Offset()).Limit(pg.PerPage).Order("id desc").Find(&accounts)

	for i := range accounts {
		db.DB.Model(&models.AccountUser{}).Where("account_id = ?", accounts[i].ID).Count(&accounts[i].UserCount)
		db.DB.Model(&models.Conversation{}).Where("account_id = ?", accounts[i].ID).Count(&accounts[i].ConversationCount)
	}

	c.JSON(http.StatusOK, gin.H{"data": accounts, "meta": pg})
}

func AccountsShow(c *gin.Context) {
	account := findAccount(c)
	if account == nil {
		return
	}
	db.DB.Model(&models.AccountUser{}).Where("account_id = ?", account.ID).Count(&account.UserCount)
	db.DB.Model(&models.Inbox{}).Where("account_id = ?", account.ID).Count(&account.InboxCount)
	db.DB.Model(&models.Conversation{}).Where("account_id = ?", account.ID).Count(&account.ConversationCount)

	var accountUsers []models.AccountUser
	db.DB.Preload("User").Where("account_id = ?", account.ID).Find(&accountUsers)

	c.JSON(http.StatusOK, gin.H{"account": account, "account_users": accountUsers})
}

func AccountsCreate(c *gin.Context) {
	var input struct {
		Name   string `json:"name" binding:"required"`
		Locale int    `json:"locale"`
		Status int    `json:"status"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	account := models.Account{Name: input.Name, Locale: input.Locale, Status: input.Status}
	if err := db.DB.Create(&account).Error; err != nil {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, account)
}

func AccountsUpdate(c *gin.Context) {
	account := findAccount(c)
	if account == nil {
		return
	}
	var input struct {
		Name                string                 `json:"name"`
		Locale              int                    `json:"locale"`
		Status              int                    `json:"status"`
		Domain              string                 `json:"domain"`
		SupportEmail        string                 `json:"support_email"`
		AutoResolveDuration *int                   `json:"auto_resolve_duration"`
		FeatureFlags        *int64                 `json:"feature_flags"`
		Limits              map[string]interface{} `json:"limits"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if input.Name != "" {
		account.Name = input.Name
	}
	account.Locale = input.Locale
	account.Status = input.Status
	account.Domain = input.Domain
	account.SupportEmail = input.SupportEmail
	account.AutoResolveDuration = input.AutoResolveDuration
	if input.FeatureFlags != nil {
		account.FeatureFlags = *input.FeatureFlags
	}
	if input.Limits != nil {
		// Only keep non-nil limit keys
		limits := models.JSONB{}
		for k, v := range input.Limits {
			if v != nil && v != "" {
				limits[k] = v
			}
		}
		account.Limits = limits
	}
	db.DB.Save(account)
	c.JSON(http.StatusOK, account)
}

func AccountsDestroy(c *gin.Context) {
	account := findAccount(c)
	if account == nil {
		return
	}
	db.DB.Delete(account)
	c.JSON(http.StatusOK, gin.H{"message": "deleted"})
}

func AccountsSeed(c *gin.Context, redisClient *redis.Client) {
	account := findAccount(c)
	if account == nil {
		return
	}
	if redisClient == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Redis not available"})
		return
	}

	// Generate job ID (UUID-like) and Sidekiq JID (24 hex chars)
	jobIDB := make([]byte, 16)
	jidB := make([]byte, 12)
	rand.Read(jobIDB)
	rand.Read(jidB)
	jobID := fmt.Sprintf("%x-%x-%x-%x-%x", jobIDB[0:4], jobIDB[4:6], jobIDB[6:8], jobIDB[8:10], jobIDB[10:])
	jid := hex.EncodeToString(jidB)

	now := time.Now().UTC()
	innerJob := map[string]interface{}{
		"job_class":           "Internal::SeedAccountJob",
		"job_id":              jobID,
		"provider_job_id":     nil,
		"queue_name":          "low",
		"priority":            nil,
		"arguments":           []interface{}{map[string]string{"_aj_globalid": fmt.Sprintf("gid://chatwoot/Account/%d", account.ID)}},
		"executions":          0,
		"exception_executions": map[string]interface{}{},
		"locale":              "en",
		"timezone":            "UTC",
		"enqueued_at":         now.Format(time.RFC3339Nano),
	}
	outerJob := map[string]interface{}{
		"class":      "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper",
		"wrapped":    "Internal::SeedAccountJob",
		"queue":      "low",
		"args":       []interface{}{innerJob},
		"jid":        jid,
		"created_at": float64(now.UnixMilli()) / 1000.0,
	}
	payload, err := json.Marshal(outerJob)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to build job payload"})
		return
	}

	ctx := context.Background()
	pipe := redisClient.Pipeline()
	pipe.SAdd(ctx, "queues", "low")
	pipe.LPush(ctx, "queue:low", string(payload))
	if _, err := pipe.Exec(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to enqueue job: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "seed job enqueued"})
}

func AccountsResetCache(c *gin.Context) {
	// Stub: clear cache keys
	c.JSON(http.StatusOK, gin.H{"message": "cache reset"})
}

func findAccount(c *gin.Context) *models.Account {
	var account models.Account
	if err := db.DB.First(&account, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return nil
	}
	return &account
}
