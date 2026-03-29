package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"chatwoot/go_super_admin/db"
	"chatwoot/go_super_admin/models"

	"github.com/gin-gonic/gin"
)

// rubySerializedValue returns a JSON-encoded Rails-compatible YAML string for the given value.
// Rails stores installation_configs using: serialize :serialized_value, coder: YAML, type: HashWithIndifferentAccess
// Format: "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: <val>\n"
func rubySerializedValue(value string) string {
	// Escape value for YAML inline scalar (quote if it contains special chars or looks like keyword)
	yamlVal := value
	needsQuote := strings.ContainsAny(value, ":#{}[]|>&*!,\n\r\t") ||
		value == "true" || value == "false" || value == "null" || value == "" ||
		strings.HasPrefix(value, " ") || strings.HasSuffix(value, " ")
	if needsQuote {
		yamlVal = "'" + strings.ReplaceAll(value, "'", "''") + "'"
	}
	yaml := "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: " + yamlVal + "\n"
	b, _ := json.Marshal(yaml) // encode as JSON string for JSONB column
	return string(b)
}

func InstallationConfigsIndex(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pg := models.NewPagination(page, 25)
	db.DB.Model(&models.InstallationConfig{}).Where("locked = false").Count(&pg.TotalCount)
	pg.SetTotal(pg.TotalCount)
	var configs []models.InstallationConfig
	db.DB.Where("locked = false").Offset(pg.Offset()).Limit(pg.PerPage).Order("name").Find(&configs)
	c.JSON(http.StatusOK, gin.H{"data": configs, "meta": pg})
}

func InstallationConfigsShow(c *gin.Context) {
	var cfg models.InstallationConfig
	if err := db.DB.First(&cfg, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	c.JSON(http.StatusOK, cfg)
}

func InstallationConfigsUpdate(c *gin.Context) {
	var cfg models.InstallationConfig
	if err := db.DB.First(&cfg, c.Param("id")).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	var input struct {
		Value string `json:"value"`
	}
	c.ShouldBindJSON(&input)
	cfg.SerializedValue = models.JSONB{"value": input.Value}
	db.DB.Save(&cfg)
	c.JSON(http.StatusOK, cfg)
}

var configSections = map[string][]string{
	"general":           {"ENABLE_ACCOUNT_SIGNUP", "FIREBASE_PROJECT_ID", "FIREBASE_CREDENTIALS", "WEBHOOK_TIMEOUT", "MAXIMUM_FILE_UPLOAD_SIZE", "WIDGET_TOKEN_EXPIRY"},
	"email":             {"MAILER_INBOUND_EMAIL_DOMAIN", "ACCOUNT_EMAILS_LIMIT", "ACCOUNT_EMAILS_PLAN_LIMITS"},
	"facebook":          {"FB_APP_ID", "FB_VERIFY_TOKEN", "FB_APP_SECRET", "IG_VERIFY_TOKEN", "FACEBOOK_API_VERSION", "ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT"},
	"instagram":         {"INSTAGRAM_APP_ID", "INSTAGRAM_APP_SECRET", "INSTAGRAM_VERIFY_TOKEN", "INSTAGRAM_API_VERSION", "ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT"},
	"tiktok":            {"TIKTOK_APP_ID", "TIKTOK_APP_SECRET", "TIKTOK_API_VERSION"},
	"google":            {"GOOGLE_OAUTH_CLIENT_ID", "GOOGLE_OAUTH_CLIENT_SECRET", "GOOGLE_OAUTH_REDIRECT_URI", "ENABLE_GOOGLE_OAUTH_LOGIN"},
	"microsoft":         {"AZURE_APP_ID", "AZURE_APP_SECRET"},
	"slack":             {"SLACK_CLIENT_ID", "SLACK_CLIENT_SECRET"},
	"whatsapp_embedded": {"WHATSAPP_APP_ID", "WHATSAPP_APP_SECRET", "WHATSAPP_CONFIGURATION_ID", "WHATSAPP_API_VERSION"},
	"shopify":           {"SHOPIFY_CLIENT_ID", "SHOPIFY_CLIENT_SECRET"},
	"notion":            {"NOTION_CLIENT_ID", "NOTION_CLIENT_SECRET"},
	"custom_branding":   {"LOGO_THUMBNAIL", "LOGO", "LOGO_DARK", "BRAND_NAME", "INSTALLATION_NAME", "BRAND_URL", "WIDGET_BRAND_URL", "TERMS_URL", "PRIVACY_URL", "DISPLAY_MANIFEST"},
}

var allowedAppConfigs = func() []string {
	all := []string{}
	seen := map[string]bool{}
	for _, keys := range configSections {
		for _, k := range keys {
			if !seen[k] {
				all = append(all, k)
				seen[k] = true
			}
		}
	}
	return all
}()

func AppConfigsShow(c *gin.Context) {
	section := c.Query("config")
	keys := allowedAppConfigs
	if section != "" {
		if sectionKeys, ok := configSections[section]; ok {
			keys = sectionKeys
		}
	}

	configs := map[string]string{}
	var rows []models.InstallationConfig
	db.DB.Where("name IN ?", keys).Find(&rows)
	for _, r := range rows {
		configs[r.Name] = r.Value()
	}
	c.JSON(http.StatusOK, gin.H{"configs": configs, "allowed_keys": keys, "section": section})
}

func AppConfigsUpdate(c *gin.Context) {
	section := c.Query("config")
	var input map[string]string
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	allowed := map[string]bool{}
	keys := allowedAppConfigs
	if section != "" {
		if sectionKeys, ok := configSections[section]; ok {
			keys = sectionKeys
		}
	}
	for _, k := range keys {
		allowed[k] = true
	}
	for key, value := range input {
		if !allowed[key] {
			continue
		}
		db.DB.Exec(
			`INSERT INTO installation_configs (name, serialized_value, locked, created_at, updated_at)
             VALUES (?, ?, false, NOW(), NOW())
             ON CONFLICT (name) DO UPDATE SET serialized_value = EXCLUDED.serialized_value, updated_at = NOW()`,
			key, rubySerializedValue(value),
		)
	}
	c.JSON(http.StatusOK, gin.H{"message": "saved"})
}
