package main

import (
	"log"

	"chatwoot/go_super_admin/config"
	"chatwoot/go_super_admin/db"
	"chatwoot/go_super_admin/handlers"
	"chatwoot/go_super_admin/middleware"
	"chatwoot/go_super_admin/router"

	"github.com/redis/go-redis/v9"
)

func main() {
	cfg := config.Load()

	if err := db.Init(cfg); err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}
	log.Println("Connected to database")

	middleware.SetJWTSecret(cfg.SessionKey)
	handlers.StoragePath = cfg.StoragePath

	opt, err := redis.ParseURL(cfg.RedisURL)
	var redisClient *redis.Client
	if err == nil {
		redisClient = redis.NewClient(opt)
		log.Println("Redis client initialized")
	} else {
		log.Printf("Redis not available: %v", err)
	}

	r := router.Setup(redisClient)

	log.Printf("Super Admin server starting on :%s", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("server failed: %v", err)
	}
}
