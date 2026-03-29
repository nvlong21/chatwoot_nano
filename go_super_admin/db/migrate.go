package db

import (
	"embed"
	"fmt"
	"log"
	"sort"
	"strings"
)

//go:embed migrations/*.sql
var migrationsFS embed.FS

func Migrate() error {
	if err := DB.Exec(`CREATE TABLE IF NOT EXISTS go_schema_migrations (
		version    VARCHAR(255) PRIMARY KEY,
		applied_at TIMESTAMP   NOT NULL DEFAULT NOW()
	)`).Error; err != nil {
		return fmt.Errorf("failed to create go_schema_migrations table: %w", err)
	}

	var applied []string
	if err := DB.Raw("SELECT version FROM go_schema_migrations ORDER BY version").Scan(&applied).Error; err != nil {
		return fmt.Errorf("failed to query applied migrations: %w", err)
	}
	appliedSet := make(map[string]bool, len(applied))
	for _, v := range applied {
		appliedSet[v] = true
	}

	entries, err := migrationsFS.ReadDir("migrations")
	if err != nil {
		return fmt.Errorf("failed to read migrations dir: %w", err)
	}

	var files []string
	for _, e := range entries {
		if !e.IsDir() && strings.HasSuffix(e.Name(), ".sql") {
			files = append(files, e.Name())
		}
	}
	sort.Strings(files)

	pending := 0
	for _, file := range files {
		version := strings.TrimSuffix(file, ".sql")
		if appliedSet[version] {
			continue
		}
		pending++

		content, err := migrationsFS.ReadFile("migrations/" + file)
		if err != nil {
			return fmt.Errorf("failed to read migration %s: %w", file, err)
		}

		if err := DB.Exec(string(content)).Error; err != nil {
			return fmt.Errorf("failed to run migration %s: %w", file, err)
		}

		if err := DB.Exec("INSERT INTO go_schema_migrations (version) VALUES (?)", version).Error; err != nil {
			return fmt.Errorf("failed to record migration %s: %w", file, err)
		}
		log.Printf("Applied migration: %s", file)
	}

	if pending == 0 {
		log.Println("Migrations: up to date")
	}
	return nil
}
