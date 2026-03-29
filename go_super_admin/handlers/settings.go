package handlers

import (
	"net/http"
	"runtime"

	"github.com/gin-gonic/gin"
)

func SettingsShow(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"go_version": runtime.Version(),
		"go_os":      runtime.GOOS,
		"go_arch":    runtime.GOARCH,
		"num_cpu":    runtime.NumCPU(),
	})
}

func SettingsRefresh(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "refreshed"})
}
