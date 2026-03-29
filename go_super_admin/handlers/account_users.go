package handlers

import (
	"net/http"

	"chatwoot/go_super_admin/db"
	"chatwoot/go_super_admin/models"

	"github.com/gin-gonic/gin"
)

func AccountUsersCreate(c *gin.Context) {
	var input struct {
		AccountID int `json:"account_id" binding:"required"`
		UserID    int `json:"user_id" binding:"required"`
		Role      int `json:"role"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	au := models.AccountUser{AccountID: input.AccountID, UserID: input.UserID, Role: input.Role}
	if err := db.DB.Create(&au).Error; err != nil {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, au)
}

func AccountUsersDestroy(c *gin.Context) {
	var au models.AccountUser
	if err := db.DB.First(&au, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	db.DB.Delete(&au)
	c.JSON(http.StatusOK, gin.H{"message": "deleted"})
}
