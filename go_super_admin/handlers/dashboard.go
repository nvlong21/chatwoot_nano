package handlers

import (
	"net/http"
	"time"

	"chatwoot/go_super_admin/db"
	"chatwoot/go_super_admin/models"

	"github.com/gin-gonic/gin"
)

func Dashboard(c *gin.Context) {
	var accountCount, userCount, inboxCount, conversationCount int64
	db.DB.Model(&models.Account{}).Count(&accountCount)
	db.DB.Model(&models.User{}).Where("type != 'SuperAdmin'").Count(&userCount)
	db.DB.Model(&models.Inbox{}).Count(&inboxCount)
	db.DB.Model(&models.Conversation{}).Count(&conversationCount)

	type DayCount struct {
		Day   time.Time `gorm:"column:day"`
		Count int64     `gorm:"column:count"`
	}
	var dayCounts []DayCount
	db.DB.Model(&models.Conversation{}).
		Select("DATE(created_at) as day, COUNT(*) as count").
		Where("created_at >= ?", time.Now().AddDate(0, 0, -30)).
		Group("DATE(created_at)").
		Order("day ASC").
		Scan(&dayCounts)

	daily := make([]gin.H, len(dayCounts))
	for i, d := range dayCounts {
		daily[i] = gin.H{"date": d.Day.Format("2006-01-02"), "count": d.Count}
	}

	c.JSON(http.StatusOK, gin.H{
		"account_count":      accountCount,
		"user_count":         userCount,
		"inbox_count":        inboxCount,
		"conversation_count": conversationCount,
		"daily_conversations": daily,
	})
}
