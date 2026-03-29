package handlers

import (
	"net/http"
	"time"

	"chatwoot/go_app/db"
	"chatwoot/go_app/middleware"
	"chatwoot/go_app/models"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type loginInput struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func Login(c *gin.Context) {
	var input loginInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	if err := db.DB.Where("email = ?", input.Email).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.EncryptedPassword), []byte(input.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	var accountUser models.AccountUser
	if err := db.DB.Where("user_id = ?", user.ID).First(&accountUser).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "user has no associated account"})
		return
	}

	claims := jwt.MapClaims{
		"sub":        user.ID,
		"account_id": accountUser.AccountID,
		"exp":        time.Now().Add(24 * time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(middleware.JWTSecret)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token": tokenString,
		"user": gin.H{
			"id":           user.ID,
			"name":         user.Name,
			"email":        user.Email,
			"display_name": user.DisplayName,
			"availability": user.Availability,
		},
		"account_id": accountUser.AccountID,
	})
}

func Profile(c *gin.Context) {
	userID := c.GetInt("user_id")
	accountID := c.GetInt("account_id")

	var user models.User
	if err := db.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":           user.ID,
		"name":         user.Name,
		"email":        user.Email,
		"display_name": user.DisplayName,
		"availability": user.Availability,
		"type":         user.Type,
		"account_id":   accountID,
	})
}
