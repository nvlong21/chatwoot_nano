package handlers

import (
	"math"
	"net/http"
	"strconv"
	"time"

	"chatwoot/go_app/db"
	"chatwoot/go_app/models"

	"github.com/gin-gonic/gin"
)

const pageSize = 25

var statusMap = map[string]int{
	"open":     0,
	"resolved": 1,
	"pending":  2,
	"snoozed":  3,
}

var statusReverseMap = map[int]string{
	0: "open",
	1: "resolved",
	2: "pending",
	3: "snoozed",
}

func ConversationsIndex(c *gin.Context) {
	accountID := c.GetInt("account_id")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	if page < 1 {
		page = 1
	}
	offset := (page - 1) * pageSize

	query := db.DB.Model(&models.Conversation{}).Where("account_id = ?", accountID)

	if status := c.Query("status"); status != "" {
		if statusInt, ok := statusMap[status]; ok {
			query = query.Where("status = ?", statusInt)
		}
	}
	if assigneeID := c.Query("assignee_id"); assigneeID != "" {
		query = query.Where("assignee_id = ?", assigneeID)
	}
	if inboxID := c.Query("inbox_id"); inboxID != "" {
		query = query.Where("inbox_id = ?", inboxID)
	}
	if teamID := c.Query("team_id"); teamID != "" {
		query = query.Where("team_id = ?", teamID)
	}

	var total int64
	query.Count(&total)

	var conversations []models.Conversation
	err := query.
		Preload("Inbox").
		Preload("Contact").
		Preload("Assignee").
		Order("last_activity_at DESC").
		Limit(pageSize).
		Offset(offset).
		Find(&conversations).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	for i := range conversations {
		var unread int64
		db.DB.Model(&models.Message{}).
			Where("conversation_id = ? AND message_type = 0 AND created_at > ?",
				conversations[i].ID, time.Now().Add(-30*24*time.Hour)).
			Count(&unread)
		conversations[i].UnreadCount = unread
	}

	totalPages := int(math.Ceil(float64(total) / float64(pageSize)))

	c.JSON(http.StatusOK, gin.H{
		"data": conversations,
		"meta": gin.H{
			"total_count":  total,
			"current_page": page,
			"total_pages":  totalPages,
		},
	})
}

func ConversationsShow(c *gin.Context) {
	accountID := c.GetInt("account_id")
	id := c.Param("id")

	var conversation models.Conversation
	err := db.DB.
		Preload("Inbox").
		Preload("Contact").
		Preload("Assignee").
		Where("id = ? AND account_id = ?", id, accountID).
		First(&conversation).Error
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "conversation not found"})
		return
	}

	c.JSON(http.StatusOK, conversation)
}

func ConversationsUpdateStatus(c *gin.Context) {
	accountID := c.GetInt("account_id")
	id := c.Param("id")

	var input struct {
		Status string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	statusInt, ok := statusMap[input.Status]
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid status value"})
		return
	}

	var conversation models.Conversation
	if err := db.DB.Where("id = ? AND account_id = ?", id, accountID).First(&conversation).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "conversation not found"})
		return
	}

	if err := db.DB.Model(&conversation).Updates(map[string]interface{}{
		"status":           statusInt,
		"last_activity_at": time.Now(),
	}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": input.Status})
}

func ConversationsUpdateAssignee(c *gin.Context) {
	accountID := c.GetInt("account_id")
	id := c.Param("id")

	var input struct {
		AssigneeID *int `json:"assignee_id"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var conversation models.Conversation
	if err := db.DB.Where("id = ? AND account_id = ?", id, accountID).First(&conversation).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "conversation not found"})
		return
	}

	updates := map[string]interface{}{
		"assignee_id":      input.AssigneeID,
		"last_activity_at": time.Now(),
	}
	if err := db.DB.Model(&conversation).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	db.DB.
		Preload("Inbox").
		Preload("Contact").
		Preload("Assignee").
		First(&conversation, conversation.ID)

	c.JSON(http.StatusOK, conversation)
}

func ConversationsUpdate(c *gin.Context) {
	accountID := c.GetInt("account_id")
	id := c.Param("id")

	var input struct {
		Priority *string `json:"priority"`
		TeamID   *int    `json:"team_id"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var conversation models.Conversation
	if err := db.DB.Where("id = ? AND account_id = ?", id, accountID).First(&conversation).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "conversation not found"})
		return
	}

	updates := map[string]interface{}{"last_activity_at": time.Now()}
	if input.Priority != nil {
		updates["priority"] = input.Priority
	}
	if input.TeamID != nil {
		updates["team_id"] = input.TeamID
	}

	if err := db.DB.Model(&conversation).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	db.DB.
		Preload("Inbox").
		Preload("Contact").
		Preload("Assignee").
		First(&conversation, conversation.ID)

	c.JSON(http.StatusOK, conversation)
}
