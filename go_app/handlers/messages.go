package handlers

import (
	"net/http"
	"strconv"
	"time"

	"chatwoot/go_app/db"
	"chatwoot/go_app/models"

	"github.com/gin-gonic/gin"
)

func MessagesIndex(c *gin.Context) {
	accountID := c.GetInt("account_id")
	conversationID := c.Param("conversation_id")

	// Verify conversation belongs to account
	var conversation models.Conversation
	if err := db.DB.Where("id = ? AND account_id = ?", conversationID, accountID).First(&conversation).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "conversation not found"})
		return
	}

	var messages []models.Message
	if err := db.DB.
		Where("conversation_id = ? AND account_id = ?", conversationID, accountID).
		Order("created_at ASC").
		Find(&messages).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Collect sender IDs by type
	userIDs := map[int]bool{}
	contactIDs := map[int]bool{}
	for _, m := range messages {
		if m.SenderID == nil {
			continue
		}
		if m.SenderType == "User" {
			userIDs[*m.SenderID] = true
		} else if m.SenderType == "Contact" {
			contactIDs[*m.SenderID] = true
		}
	}

	// Fetch users
	usersMap := map[int]*models.User{}
	if len(userIDs) > 0 {
		ids := make([]int, 0, len(userIDs))
		for id := range userIDs {
			ids = append(ids, id)
		}
		var users []models.User
		db.DB.Where("id IN ?", ids).Find(&users)
		for i := range users {
			usersMap[users[i].ID] = &users[i]
		}
	}

	// Fetch contacts
	contactsMap := map[int]*models.Contact{}
	if len(contactIDs) > 0 {
		ids := make([]int, 0, len(contactIDs))
		for id := range contactIDs {
			ids = append(ids, id)
		}
		var contacts []models.Contact
		db.DB.Where("id IN ?", ids).Find(&contacts)
		for i := range contacts {
			contactsMap[contacts[i].ID] = &contacts[i]
		}
	}

	// Populate sender info
	for i := range messages {
		if messages[i].SenderID == nil {
			continue
		}
		sid := *messages[i].SenderID
		if messages[i].SenderType == "User" {
			if u, ok := usersMap[sid]; ok {
				messages[i].Sender = &models.SenderInfo{
					ID:    u.ID,
					Name:  u.Name,
					Email: u.Email,
					Type:  "user",
				}
			}
		} else if messages[i].SenderType == "Contact" {
			if ct := contactsMap[sid]; ct != nil {
				messages[i].Sender = &models.SenderInfo{
					ID:   ct.ID,
					Name: ct.Name,
					Type: "contact",
				}
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{"payload": messages})
}

func MessagesCreate(c *gin.Context) {
	accountID := c.GetInt("account_id")
	userID := c.GetInt("user_id")
	conversationID := c.Param("conversation_id")

	convIDInt, err := strconv.Atoi(conversationID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid conversation_id"})
		return
	}

	var conversation models.Conversation
	if err := db.DB.Where("id = ? AND account_id = ?", convIDInt, accountID).First(&conversation).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "conversation not found"})
		return
	}

	var input struct {
		Content     string `json:"content" binding:"required"`
		MessageType int    `json:"message_type"`
		Private     bool   `json:"private"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if input.MessageType == 0 {
		input.MessageType = 1 // default outgoing
	}

	msg := models.Message{
		AccountID:      accountID,
		InboxID:        conversation.InboxID,
		ConversationID: convIDInt,
		SenderID:       &userID,
		SenderType:     "User",
		Content:        input.Content,
		MessageType:    input.MessageType,
		ContentType:    0, // text
		Private:        input.Private,
		Status:         "sent",
	}

	if err := db.DB.Create(&msg).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	db.DB.Model(&conversation).Update("last_activity_at", time.Now())

	// Populate sender
	var user models.User
	if err := db.DB.First(&user, userID).Error; err == nil {
		msg.Sender = &models.SenderInfo{
			ID:    user.ID,
			Name:  user.Name,
			Email: user.Email,
			Type:  "user",
		}
	}

	c.JSON(http.StatusCreated, msg)
}

func MessagesDelete(c *gin.Context) {
	accountID := c.GetInt("account_id")
	conversationID := c.Param("conversation_id")
	messageID := c.Param("id")

	var message models.Message
	if err := db.DB.
		Where("id = ? AND conversation_id = ? AND account_id = ?", messageID, conversationID, accountID).
		First(&message).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "message not found"})
		return
	}

	if err := db.DB.Delete(&message).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"success": true})
}
