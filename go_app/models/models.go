package models

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"time"
)

// JSONB is a map type that implements driver.Valuer and sql.Scanner for PostgreSQL jsonb columns.
type JSONB map[string]interface{}

func (j JSONB) Value() (driver.Value, error) {
	if j == nil {
		return nil, nil
	}
	b, err := json.Marshal(j)
	if err != nil {
		return nil, err
	}
	return string(b), nil
}

func (j *JSONB) Scan(value interface{}) error {
	if value == nil {
		*j = nil
		return nil
	}
	var bytes []byte
	switch v := value.(type) {
	case []byte:
		bytes = v
	case string:
		bytes = []byte(v)
	default:
		return fmt.Errorf("JSONB: cannot scan type %T", value)
	}
	result := make(JSONB)
	if err := json.Unmarshal(bytes, &result); err != nil {
		return err
	}
	*j = result
	return nil
}

type User struct {
	ID                int        `gorm:"primaryKey;column:id" json:"id"`
	Name              string     `gorm:"column:name" json:"name"`
	DisplayName       string     `gorm:"column:display_name" json:"display_name"`
	Email             string     `gorm:"column:email" json:"email"`
	EncryptedPassword string     `gorm:"column:encrypted_password" json:"-"`
	Type              string     `gorm:"column:type" json:"type"`
	ConfirmedAt       *time.Time `gorm:"column:confirmed_at" json:"confirmed_at"`
	Availability      int        `gorm:"column:availability" json:"availability"`
	CreatedAt         time.Time  `gorm:"column:created_at" json:"created_at"`
	UpdatedAt         time.Time  `gorm:"column:updated_at" json:"updated_at"`
}

type Account struct {
	ID        int       `gorm:"primaryKey;column:id" json:"id"`
	Name      string    `gorm:"column:name" json:"name"`
	CreatedAt time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt time.Time `gorm:"column:updated_at" json:"updated_at"`
}

type AccountUser struct {
	ID        int       `gorm:"primaryKey;column:id" json:"id"`
	AccountID int       `gorm:"column:account_id" json:"account_id"`
	UserID    int       `gorm:"column:user_id" json:"user_id"`
	Role      int       `gorm:"column:role" json:"role"` // 0=administrator, 1=agent
	CreatedAt time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt time.Time `gorm:"column:updated_at" json:"updated_at"`
}

type Conversation struct {
	ID                   int        `gorm:"primaryKey;column:id" json:"id"`
	DisplayID            int        `gorm:"column:display_id" json:"display_id"`
	AccountID            int        `gorm:"column:account_id" json:"account_id"`
	InboxID              int        `gorm:"column:inbox_id" json:"inbox_id"`
	ContactID            int        `gorm:"column:contact_id" json:"contact_id"`
	AssigneeID           *int       `gorm:"column:assignee_id" json:"assignee_id"`
	TeamID               *int       `gorm:"column:team_id" json:"team_id"`
	Status               int        `gorm:"column:status" json:"status"` // 0=open,1=resolved,2=pending,3=snoozed
	Priority             *string    `gorm:"column:priority" json:"priority"`
	LastActivityAt       time.Time  `gorm:"column:last_activity_at" json:"last_activity_at"`
	WaitingSince         *time.Time `gorm:"column:waiting_since" json:"waiting_since"`
	FirstReplyCreatedAt  *time.Time `gorm:"column:first_reply_created_at" json:"first_reply_created_at"`
	AdditionalAttributes JSONB      `gorm:"column:additional_attributes;type:jsonb" json:"additional_attributes"`
	CreatedAt            time.Time  `gorm:"column:created_at" json:"created_at"`
	UpdatedAt            time.Time  `gorm:"column:updated_at" json:"updated_at"`
	// Preloaded associations
	Inbox    *Inbox   `gorm:"foreignKey:InboxID" json:"inbox,omitempty"`
	Contact  *Contact `gorm:"foreignKey:ContactID" json:"contact,omitempty"`
	Assignee *User    `gorm:"foreignKey:AssigneeID" json:"assignee,omitempty"`
	// Computed
	UnreadCount int64 `gorm:"-" json:"unread_count"`
}

type Message struct {
	ID             int       `gorm:"primaryKey;column:id" json:"id"`
	AccountID      int       `gorm:"column:account_id" json:"account_id"`
	InboxID        int       `gorm:"column:inbox_id" json:"inbox_id"`
	ConversationID int       `gorm:"column:conversation_id" json:"conversation_id"`
	SenderID       *int      `gorm:"column:sender_id" json:"sender_id"`
	SenderType     string    `gorm:"column:sender_type" json:"sender_type"`
	Content        string    `gorm:"column:content" json:"content"`
	MessageType    int       `gorm:"column:message_type" json:"message_type"` // 0=incoming,1=outgoing,2=activity
	ContentType    int       `gorm:"column:content_type" json:"content_type"` // 0=text
	Private        bool      `gorm:"column:private" json:"private"`
	Status         string    `gorm:"column:status" json:"status"`
	CreatedAt      time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt      time.Time `gorm:"column:updated_at" json:"updated_at"`
	// Computed sender info
	Sender *SenderInfo `gorm:"-" json:"sender,omitempty"`
}

type SenderInfo struct {
	ID        int    `json:"id"`
	Name      string `json:"name"`
	Email     string `json:"email,omitempty"`
	Type      string `json:"type"` // "user" or "contact"
	AvatarURL string `json:"avatar_url"`
}

type Contact struct {
	ID                   int       `gorm:"primaryKey;column:id" json:"id"`
	AccountID            int       `gorm:"column:account_id" json:"account_id"`
	Name                 string    `gorm:"column:name" json:"name"`
	Email                string    `gorm:"column:email" json:"email"`
	PhoneNumber          string    `gorm:"column:phone_number" json:"phone_number"`
	Identifier           string    `gorm:"column:identifier" json:"identifier"`
	AdditionalAttributes JSONB     `gorm:"column:additional_attributes;type:jsonb" json:"additional_attributes"`
	CreatedAt            time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt            time.Time `gorm:"column:updated_at" json:"updated_at"`
}

type Inbox struct {
	ID          int       `gorm:"primaryKey;column:id" json:"id"`
	AccountID   int       `gorm:"column:account_id" json:"account_id"`
	Name        string    `gorm:"column:name" json:"name"`
	ChannelType string    `gorm:"column:channel_type" json:"channel_type"`
	CreatedAt   time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt   time.Time `gorm:"column:updated_at" json:"updated_at"`
}

type Team struct {
	ID        int       `gorm:"primaryKey;column:id" json:"id"`
	AccountID int       `gorm:"column:account_id" json:"account_id"`
	Name      string    `gorm:"column:name" json:"name"`
	CreatedAt time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt time.Time `gorm:"column:updated_at" json:"updated_at"`
}

type Label struct {
	ID          int       `gorm:"primaryKey;column:id" json:"id"`
	AccountID   int       `gorm:"column:account_id" json:"account_id"`
	Title       string    `gorm:"column:title" json:"title"`
	Color       string    `gorm:"column:color" json:"color"`
	Description string    `gorm:"column:description" json:"description"`
	CreatedAt   time.Time `gorm:"column:created_at" json:"created_at"`
	UpdatedAt   time.Time `gorm:"column:updated_at" json:"updated_at"`
}

// ConversationLabelTag maps to the taggings table used by acts-as-taggable.
type ConversationLabelTag struct {
	ID           int64     `gorm:"primaryKey;column:id"`
	TaggableID   int64     `gorm:"column:taggable_id"`
	TaggableType string    `gorm:"column:taggable_type"`
	TagID        int64     `gorm:"column:tag_id"`
	Tagger       string    `gorm:"column:tagger_type"`
	Context      string    `gorm:"column:context"`
	CreatedAt    time.Time `gorm:"column:created_at"`
}

func (ConversationLabelTag) TableName() string { return "taggings" }

type Notification struct {
	ID               int        `gorm:"primaryKey;column:id" json:"id"`
	UserID           int        `gorm:"column:user_id" json:"user_id"`
	AccountID        int        `gorm:"column:account_id" json:"account_id"`
	PrimaryActorType string     `gorm:"column:primary_actor_type" json:"primary_actor_type"`
	PrimaryActorID   int        `gorm:"column:primary_actor_id" json:"primary_actor_id"`
	NotificationType string     `gorm:"column:notification_type" json:"notification_type"`
	ReadAt           *time.Time `gorm:"column:read_at" json:"read_at"`
	CreatedAt        time.Time  `gorm:"column:created_at" json:"created_at"`
}
