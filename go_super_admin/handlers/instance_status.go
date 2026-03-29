package handlers

import (
	"context"
	"net/http"
	"strings"

	"chatwoot/go_super_admin/db"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

func InstanceStatusShow(c *gin.Context, redisClient *redis.Client) {
	result := gin.H{}

	sqlDB, err := db.DB.DB()
	if err == nil && sqlDB.Ping() == nil {
		result["db_status"] = "ok"
	} else {
		result["db_status"] = "error"
		if err != nil {
			result["db_error"] = err.Error()
		}
	}

	if redisClient != nil {
		info, err := redisClient.Info(context.Background()).Result()
		if err != nil {
			result["redis_status"] = "error"
			result["redis_error"] = err.Error()
		} else {
			result["redis_status"] = "ok"
			result["redis_info"] = parseRedisInfo(info)
		}
	} else {
		result["redis_status"] = "not configured"
	}

	c.JSON(http.StatusOK, result)
}

func parseRedisInfo(info string) map[string]string {
	m := map[string]string{}
	for _, line := range strings.Split(info, "\r\n") {
		parts := strings.SplitN(line, ":", 2)
		if len(parts) == 2 {
			m[parts[0]] = parts[1]
		}
	}
	return m
}
