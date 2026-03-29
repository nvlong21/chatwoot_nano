package handlers

import (
	"net/http"
	"strconv"

	"chatwoot/go_super_admin/db"
	"chatwoot/go_super_admin/models"

	"github.com/gin-gonic/gin"
)

func AccessTokensIndex(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	ownerType := c.Query("owner_type")
	pg := models.NewPagination(page, 25)

	query := db.DB.Model(&models.AccessToken{})
	if ownerType != "" {
		query = query.Where("owner_type = ?", ownerType)
	}
	query.Count(&pg.TotalCount)
	pg.SetTotal(pg.TotalCount)

	var tokens []models.AccessToken
	query.Offset(pg.Offset()).Limit(pg.PerPage).Order("id desc").Find(&tokens)
	c.JSON(http.StatusOK, gin.H{"data": tokens, "meta": pg})
}

func AccessTokensShow(c *gin.Context) {
	var token models.AccessToken
	if err := db.DB.First(&token, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	c.JSON(http.StatusOK, token)
}
