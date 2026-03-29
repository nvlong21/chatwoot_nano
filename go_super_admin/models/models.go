package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

// JSONB is a generic JSONB type for PostgreSQL
type JSONB map[string]interface{}

func (j JSONB) Value() (driver.Value, error) {
	return json.Marshal(j)
}

func (j *JSONB) Scan(value interface{}) error {
	if value == nil {
		*j = JSONB{}
		return nil
	}
	var bytes []byte
	switch v := value.(type) {
	case []byte:
		bytes = v
	case string:
		bytes = []byte(v)
	default:
		return fmt.Errorf("unsupported type: %T", value)
	}
	// Try to unmarshal as a JSON object first
	if err := json.Unmarshal(bytes, (*map[string]interface{})(j)); err == nil {
		return nil
	}
	// Fall back: bare JSON value (string, number, bool, null) — wrap as {"value": ...}
	var raw interface{}
	if err := json.Unmarshal(bytes, &raw); err != nil {
		return err
	}
	*j = JSONB{"value": raw}
	return nil
}

// User represents both User and SuperAdmin (STI via type column)
type User struct {
	ID                int        `gorm:"primaryKey;column:id" json:"id"`
	Name              string     `gorm:"column:name" json:"name"`
	DisplayName       string     `gorm:"column:display_name" json:"display_name"`
	Email             string     `gorm:"column:email" json:"email"`
	EncryptedPassword string     `gorm:"column:encrypted_password" json:"-"`
	Type              string     `gorm:"column:type" json:"type"`
	ConfirmedAt       *time.Time `gorm:"column:confirmed_at" json:"confirmed_at"`
	CreatedAt         time.Time  `gorm:"column:created_at" json:"created_at"`
	UpdatedAt         time.Time  `gorm:"column:updated_at" json:"updated_at"`
	AccountUsers      []AccountUser `gorm:"foreignKey:UserID" json:"account_users,omitempty"`
}

func (User) TableName() string { return "users" }

// Account represents a Chatwoot workspace
type Account struct {
	ID               int        `gorm:"primaryKey;column:id" json:"id"`
	Name             string     `gorm:"column:name" json:"name"`
	Locale           int        `gorm:"column:locale" json:"locale"`
	Status           int        `gorm:"column:status" json:"status"`
	Domain           string     `gorm:"column:domain" json:"domain"`
	SupportEmail     string     `gorm:"column:support_email" json:"support_email"`
	FeatureFlags     int64      `gorm:"column:feature_flags" json:"feature_flags"`
	AutoResolveDuration *int    `gorm:"column:auto_resolve_duration" json:"auto_resolve_duration"`
	Limits           JSONB      `gorm:"column:limits;type:jsonb" json:"limits"`
	CustomAttributes JSONB      `gorm:"column:custom_attributes;type:jsonb" json:"custom_attributes"`
	CreatedAt        time.Time  `gorm:"column:created_at" json:"created_at"`
	UpdatedAt        time.Time  `gorm:"column:updated_at" json:"updated_at"`
	// Computed fields (not in DB)
	UserCount         int64 `gorm:"-" json:"user_count"`
	InboxCount        int64 `gorm:"-" json:"inbox_count"`
	ConversationCount int64 `gorm:"-" json:"conversation_count"`
}

func (Account) TableName() string { return "accounts" }

func (a *Account) StatusName() string {
	switch a.Status {
	case 0:
		return "active"
	case 1:
		return "suspended"
	default:
		return "unknown"
	}
}

func (a *Account) LocaleName() string {
	locales := map[int]string{
		0: "en", 1: "ar", 2: "ca", 3: "cs", 4: "da", 5: "de",
		6: "el", 7: "es", 8: "fa", 9: "fi", 10: "fr", 11: "he",
		12: "hu", 13: "id", 14: "it", 15: "ja", 16: "ko", 17: "ml",
		18: "nl", 19: "no", 20: "pl", 21: "pt", 22: "pt_BR", 23: "ro",
		24: "ru", 25: "sv", 26: "ta", 27: "th", 28: "tr", 29: "uk",
		30: "vi", 31: "zh_CN", 32: "zh_TW",
	}
	if name, ok := locales[a.Locale]; ok {
		return name
	}
	return "en"
}

// AccessToken
type AccessToken struct {
	ID        int       `gorm:"primaryKey;column:id" json:"id"`
	OwnerType string    `gorm:"column:owner_type" json:"owner_type"`
	OwnerID   int64     `gorm:"column:owner_id" json:"owner_id"`
	Token     string    `gorm:"column:token" json:"token"`
	CreatedAt time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (AccessToken) TableName() string { return "access_tokens" }

// AccountUser represents account-user relationship
type AccountUser struct {
	ID        int       `gorm:"primaryKey;column:id" json:"id"`
	AccountID int       `gorm:"column:account_id" json:"account_id"`
	UserID    int       `gorm:"column:user_id" json:"user_id"`
	Role      int       `gorm:"column:role" json:"role"`
	InviterID *int      `gorm:"column:inviter_id" json:"inviter_id"`
	CreatedAt time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt time.Time `gorm:"column:updated_at" json:"updated_at"`
	Account   *Account  `gorm:"foreignKey:AccountID" json:"account,omitempty"`
	User      *User     `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Inviter   *User     `gorm:"foreignKey:InviterID" json:"inviter,omitempty"`
}

func (AccountUser) TableName() string { return "account_users" }

func (au *AccountUser) RoleName() string {
	switch au.Role {
	case 0:
		return "agent"
	case 1:
		return "administrator"
	default:
		return "agent"
	}
}

// AgentBot
type AgentBot struct {
	ID          int       `gorm:"primaryKey;column:id" json:"id"`
	Name        string    `gorm:"column:name" json:"name"`
	Description string    `gorm:"column:description" json:"description"`
	OutgoingURL string    `gorm:"column:outgoing_url" json:"outgoing_url"`
	AccountID   *int      `gorm:"column:account_id" json:"account_id"`
	BotType     int       `gorm:"column:bot_type" json:"bot_type"`
	CreatedAt   time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt   time.Time `gorm:"column:updated_at" json:"updated_at"`
	Account     *Account  `gorm:"foreignKey:AccountID" json:"account,omitempty"`
}

func (AgentBot) TableName() string { return "agent_bots" }

// PlatformApp
type PlatformApp struct {
	ID        int       `gorm:"primaryKey;column:id" json:"id"`
	Name      string    `gorm:"column:name" json:"name"`
	CreatedAt time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (PlatformApp) TableName() string { return "platform_apps" }

// InstallationConfig
type InstallationConfig struct {
	ID              int       `gorm:"primaryKey;column:id" json:"id"`
	Name            string    `gorm:"column:name" json:"name"`
	SerializedValue JSONB     `gorm:"column:serialized_value;type:jsonb" json:"serialized_value"`
	Locked          bool      `gorm:"column:locked" json:"locked"`
	CreatedAt       time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt       time.Time `gorm:"column:updated_at" json:"updated_at"`
}

func (InstallationConfig) TableName() string { return "installation_configs" }

func (ic *InstallationConfig) Value() string {
	if v, ok := ic.SerializedValue["value"]; ok {
		s := fmt.Sprintf("%v", v)
		// Handle Rails YAML serialization format:
		// "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\nvalue: some_val\n"
		if strings.HasPrefix(s, "---") {
			for _, line := range strings.Split(s, "\n") {
				if strings.HasPrefix(line, "value: ") {
					val := strings.TrimPrefix(line, "value: ")
					// Strip surrounding single-quotes used by YAML for special values
					if len(val) >= 2 && val[0] == '\'' && val[len(val)-1] == '\'' {
						val = strings.ReplaceAll(val[1:len(val)-1], "''", "'")
					}
					return val
				}
			}
		}
		return s
	}
	return ""
}

// Inbox (for counts)
type Inbox struct {
	ID        int `gorm:"primaryKey;column:id"`
	AccountID int `gorm:"column:account_id"`
}

func (Inbox) TableName() string { return "inboxes" }

// Conversation (for counts)
type Conversation struct {
	ID        int       `gorm:"primaryKey;column:id"`
	AccountID int       `gorm:"column:account_id"`
	CreatedAt time.Time `gorm:"column:created_at"`
}

func (Conversation) TableName() string { return "conversations" }

// Pagination helpers
type Pagination struct {
	Page       int
	PerPage    int
	TotalCount int64
	TotalPages int
}

func NewPagination(page, perPage int) *Pagination {
	if page < 1 {
		page = 1
	}
	if perPage < 1 {
		perPage = 25
	}
	return &Pagination{Page: page, PerPage: perPage}
}

func (p *Pagination) Offset() int {
	return (p.Page - 1) * p.PerPage
}

func (p *Pagination) SetTotal(total int64) {
	p.TotalCount = total
	p.TotalPages = int((total + int64(p.PerPage) - 1) / int64(p.PerPage))
}

func (p *Pagination) HasPrev() bool { return p.Page > 1 }
func (p *Pagination) HasNext() bool { return p.Page < p.TotalPages }
func (p *Pagination) PrevPage() int  { return p.Page - 1 }
func (p *Pagination) NextPage() int  { return p.Page + 1 }
