package handlers

import (
	"net/http"

	"chatwoot/go_super_admin/db"
	"chatwoot/go_super_admin/models"

	"github.com/gin-gonic/gin"
	"strconv"
)

func AgentBotsIndex(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pg := models.NewPagination(page, 25)
	db.DB.Model(&models.AgentBot{}).Count(&pg.TotalCount)
	pg.SetTotal(pg.TotalCount)
	var bots []models.AgentBot
	db.DB.Preload("Account").Offset(pg.Offset()).Limit(pg.PerPage).Order("id desc").Find(&bots)
	c.JSON(http.StatusOK, gin.H{"data": bots, "meta": pg})
}

func AgentBotsShow(c *gin.Context) {
	var bot models.AgentBot
	if err := db.DB.Preload("Account").First(&bot, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	c.JSON(http.StatusOK, bot)
}

func AgentBotsCreate(c *gin.Context) {
	var input struct {
		Name        string `json:"name" binding:"required"`
		Description string `json:"description"`
		OutgoingURL string `json:"outgoing_url"`
		AccountID   *int   `json:"account_id"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	bot := models.AgentBot{Name: input.Name, Description: input.Description, OutgoingURL: input.OutgoingURL, AccountID: input.AccountID}
	if err := db.DB.Create(&bot).Error; err != nil {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, bot)
}

func AgentBotsUpdate(c *gin.Context) {
	var bot models.AgentBot
	if err := db.DB.First(&bot, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	var input struct {
		Name        string `json:"name"`
		Description string `json:"description"`
		OutgoingURL string `json:"outgoing_url"`
		AccountID   *int   `json:"account_id"`
	}
	c.ShouldBindJSON(&input)
	if input.Name != "" {
		bot.Name = input.Name
	}
	bot.Description = input.Description
	bot.OutgoingURL = input.OutgoingURL
	bot.AccountID = input.AccountID
	db.DB.Save(&bot)
	c.JSON(http.StatusOK, bot)
}

func AgentBotsDestroy(c *gin.Context) {
	var bot models.AgentBot
	if err := db.DB.First(&bot, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	db.DB.Delete(&bot)
	c.JSON(http.StatusOK, gin.H{"message": "deleted"})
}
