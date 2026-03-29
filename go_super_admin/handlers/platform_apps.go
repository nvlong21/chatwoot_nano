package handlers

import (
	"net/http"
	"strconv"

	"chatwoot/go_super_admin/db"
	"chatwoot/go_super_admin/models"

	"github.com/gin-gonic/gin"
)

func PlatformAppsIndex(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pg := models.NewPagination(page, 25)
	db.DB.Model(&models.PlatformApp{}).Count(&pg.TotalCount)
	pg.SetTotal(pg.TotalCount)
	var apps []models.PlatformApp
	db.DB.Offset(pg.Offset()).Limit(pg.PerPage).Order("id desc").Find(&apps)
	c.JSON(http.StatusOK, gin.H{"data": apps, "meta": pg})
}

func PlatformAppsShow(c *gin.Context) {
	var app models.PlatformApp
	if err := db.DB.First(&app, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	var token models.AccessToken
	db.DB.Where("owner_type = 'PlatformApp' AND owner_id = ?", app.ID).First(&token)
	c.JSON(http.StatusOK, gin.H{"app": app, "token": token})
}

func PlatformAppsCreate(c *gin.Context) {
	var input struct {
		Name string `json:"name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	app := models.PlatformApp{Name: input.Name}
	if err := db.DB.Create(&app).Error; err != nil {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, app)
}

func PlatformAppsUpdate(c *gin.Context) {
	var app models.PlatformApp
	if err := db.DB.First(&app, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	var input struct {
		Name string `json:"name"`
	}
	c.ShouldBindJSON(&input)
	if input.Name != "" {
		app.Name = input.Name
	}
	db.DB.Save(&app)
	c.JSON(http.StatusOK, app)
}

func PlatformAppsDestroy(c *gin.Context) {
	var app models.PlatformApp
	if err := db.DB.First(&app, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	db.DB.Delete(&app)
	c.JSON(http.StatusOK, gin.H{"message": "deleted"})
}
