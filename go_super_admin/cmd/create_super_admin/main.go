package main

import (
	"fmt"
	"log"
	"os"

	"chatwoot/go_super_admin/config"
	"chatwoot/go_super_admin/db"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func main() {
	if len(os.Args) < 4 {
		fmt.Println("Usage: create_super_admin <name> <email> <password>")
		os.Exit(1)
	}

	name := os.Args[1]
	email := os.Args[2]
	password := os.Args[3]

	cfg := config.Load()
	if err := db.Init(cfg); err != nil {
		log.Fatalf("DB connection failed: %v", err)
	}

	// Check if already exists
	var count int64
	db.DB.Table("users").Where("email = ? AND type = 'SuperAdmin'", email).Count(&count)
	if count > 0 {
		log.Fatalf("SuperAdmin with email %s already exists", email)
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Fatalf("Failed to hash password: %v", err)
	}

	result := db.DB.Exec(
		`INSERT INTO users (name, email, encrypted_password, type, provider, uid, confirmed_at, created_at, updated_at)
         VALUES (?, ?, ?, 'SuperAdmin', 'email', ?, NOW(), NOW(), NOW())`,
		name, email, string(hash), email,
	)
	if result.Error != nil {
		if result.Error == gorm.ErrDuplicatedKey {
			log.Fatalf("Email %s already taken", email)
		}
		log.Fatalf("Failed to create user: %v", result.Error)
	}

	fmt.Printf("✓ SuperAdmin created: %s <%s>\n", name, email)
}
