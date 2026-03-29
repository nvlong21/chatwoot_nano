package router

import (
	"chatwoot/go_super_admin/handlers"
	"chatwoot/go_super_admin/middleware"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

func Setup(redisClient *redis.Client) *gin.Engine {
	r := gin.Default()

	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:5173", "http://localhost:4000"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		AllowCredentials: true,
	}))

	api := r.Group("/super_admin/api")
	{
		api.POST("/auth/login", handlers.Login)
		api.GET("/users/:id/avatar", handlers.UsersAvatarServe)

		auth := api.Group("")
		auth.Use(middleware.RequireSuperAdmin())
		{
			auth.GET("/dashboard", handlers.Dashboard)

			auth.GET("/accounts", handlers.AccountsIndex)
			auth.POST("/accounts", handlers.AccountsCreate)
			auth.GET("/accounts/:id", handlers.AccountsShow)
			auth.PUT("/accounts/:id", handlers.AccountsUpdate)
			auth.DELETE("/accounts/:id", handlers.AccountsDestroy)
			auth.POST("/accounts/:id/seed", func(c *gin.Context) {
				handlers.AccountsSeed(c, redisClient)
			})
			auth.POST("/accounts/:id/reset_cache", handlers.AccountsResetCache)

			auth.GET("/users", handlers.UsersIndex)
			auth.POST("/users", handlers.UsersCreate)
			auth.GET("/users/:id", handlers.UsersShow)
			auth.PUT("/users/:id", handlers.UsersUpdate)
			auth.DELETE("/users/:id", handlers.UsersDestroy)
			auth.POST("/users/:id/avatar", handlers.UsersAvatarUpload)

			auth.GET("/access_tokens", handlers.AccessTokensIndex)
			auth.GET("/access_tokens/:id", handlers.AccessTokensShow)

			auth.POST("/account_users", handlers.AccountUsersCreate)
			auth.DELETE("/account_users/:id", handlers.AccountUsersDestroy)

			auth.GET("/agent_bots", handlers.AgentBotsIndex)
			auth.POST("/agent_bots", handlers.AgentBotsCreate)
			auth.GET("/agent_bots/:id", handlers.AgentBotsShow)
			auth.PUT("/agent_bots/:id", handlers.AgentBotsUpdate)
			auth.DELETE("/agent_bots/:id", handlers.AgentBotsDestroy)

			auth.GET("/platform_apps", handlers.PlatformAppsIndex)
			auth.POST("/platform_apps", handlers.PlatformAppsCreate)
			auth.GET("/platform_apps/:id", handlers.PlatformAppsShow)
			auth.PUT("/platform_apps/:id", handlers.PlatformAppsUpdate)
			auth.DELETE("/platform_apps/:id", handlers.PlatformAppsDestroy)

			auth.GET("/installation_configs", handlers.InstallationConfigsIndex)
			auth.GET("/installation_configs/:id", handlers.InstallationConfigsShow)
			auth.PUT("/installation_configs/:id", handlers.InstallationConfigsUpdate)

			auth.GET("/app_config", handlers.AppConfigsShow)
			auth.PUT("/app_config", handlers.AppConfigsUpdate)

			auth.GET("/instance_status", func(c *gin.Context) {
				handlers.InstanceStatusShow(c, redisClient)
			})
			auth.GET("/settings", handlers.SettingsShow)
			auth.POST("/settings/refresh", handlers.SettingsRefresh)
		}
	}

	// Serve Vue SPA (after `pnpm build`)
	r.Static("/super_admin/assets", "./frontend/dist/assets")
	r.NoRoute(func(c *gin.Context) {
		c.File("./frontend/dist/index.html")
	})

	return r
}
