package config

import (
	"fmt"
	"os"
)

type Config struct {
	DBHost      string
	DBPort      string
	DBUser      string
	DBPassword  string
	DBName      string
	RedisURL    string
	Port        string
	SessionKey  string
	StoragePath string
}

func Load() *Config {
	return &Config{
		DBHost:      getEnv("POSTGRES_HOST", "localhost"),
		DBPort:      getEnv("POSTGRES_PORT", "5432"),
		DBUser:      getEnv("POSTGRES_USERNAME", "postgres"),
		DBPassword:  getEnv("POSTGRES_PASSWORD", ""),
		DBName:      getEnv("POSTGRES_DATABASE", "chatwoot"),
		RedisURL:    getEnv("REDIS_URL", "redis://localhost:6379"),
		Port:        getEnv("SUPER_ADMIN_PORT", "4000"),
		SessionKey:  getEnv("SECRET_KEY_BASE", "chatwoot-super-admin-secret"),
		StoragePath: getEnv("STORAGE_PATH", "/storage"),
	}
}

func (c *Config) DSN() string {
	return fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable TimeZone=UTC",
		c.DBHost, c.DBPort, c.DBUser, c.DBPassword, c.DBName,
	)
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
