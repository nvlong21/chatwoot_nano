-- Initial schema based on db/schema.rb
-- Generated from schema version 2026_03_27_000000

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "plpgsql";

-- Table: access_tokens
CREATE TABLE IF NOT EXISTS "access_tokens" (
  "id" BIGSERIAL PRIMARY KEY,
  "owner_type" VARCHAR(255),
  "owner_id" BIGINT,
  "token" VARCHAR(255),
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_access_tokens_on_owner_type_and_owner_id" ON "access_tokens" ("owner_type", "owner_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_access_tokens_on_token" ON "access_tokens" ("token");

-- Table: account_saml_settings
CREATE TABLE IF NOT EXISTS "account_saml_settings" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" BIGINT NOT NULL,
  "sso_url" VARCHAR(255),
  "certificate" TEXT,
  "sp_entity_id" VARCHAR(255),
  "idp_entity_id" VARCHAR(255),
  "role_mappings" JSON DEFAULT '{}',
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_account_saml_settings_on_account_id" ON "account_saml_settings" ("account_id");

-- Table: account_users
CREATE TABLE IF NOT EXISTS "account_users" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" BIGINT,
  "user_id" BIGINT,
  "role" INTEGER DEFAULT 0,
  "inviter_id" BIGINT,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "active_at" TIMESTAMP,
  "availability" INTEGER DEFAULT 0 NOT NULL,
  "auto_offline" BOOLEAN DEFAULT TRUE NOT NULL,
  "custom_role_id" BIGINT,
  "agent_capacity_policy_id" BIGINT
);
CREATE UNIQUE INDEX IF NOT EXISTS "uniq_user_id_per_account_id" ON "account_users" ("account_id", "user_id");
CREATE INDEX IF NOT EXISTS "index_account_users_on_account_id" ON "account_users" ("account_id");
CREATE INDEX IF NOT EXISTS "index_account_users_on_agent_capacity_policy_id" ON "account_users" ("agent_capacity_policy_id");
CREATE INDEX IF NOT EXISTS "index_account_users_on_custom_role_id" ON "account_users" ("custom_role_id");
CREATE INDEX IF NOT EXISTS "index_account_users_on_user_id" ON "account_users" ("user_id");

-- Table: accounts
CREATE TABLE IF NOT EXISTS "accounts" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "locale" INTEGER DEFAULT 0,
  "domain" VARCHAR(100),
  "support_email" VARCHAR(100),
  "feature_flags" BIGINT DEFAULT 0 NOT NULL,
  "auto_resolve_duration" INTEGER,
  "limits" JSONB DEFAULT '{}',
  "custom_attributes" JSONB DEFAULT '{}',
  "status" INTEGER DEFAULT 0,
  "internal_attributes" JSONB DEFAULT '{}' NOT NULL,
  "settings" JSONB DEFAULT '{}'
);
CREATE INDEX IF NOT EXISTS "index_accounts_on_status" ON "accounts" ("status");

-- Table: action_mailbox_inbound_emails
CREATE TABLE IF NOT EXISTS "action_mailbox_inbound_emails" (
  "id" BIGSERIAL PRIMARY KEY,
  "status" INTEGER DEFAULT 0 NOT NULL,
  "message_id" VARCHAR(255) NOT NULL,
  "message_checksum" VARCHAR(255) NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_action_mailbox_inbound_emails_uniqueness" ON "action_mailbox_inbound_emails" ("message_id", "message_checksum");

-- Table: active_storage_attachments
CREATE TABLE IF NOT EXISTS "active_storage_attachments" (
  "id" BIGSERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "record_type" VARCHAR(255) NOT NULL,
  "record_id" BIGINT NOT NULL,
  "blob_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id");

-- Table: active_storage_blobs
CREATE TABLE IF NOT EXISTS "active_storage_blobs" (
  "id" BIGSERIAL PRIMARY KEY,
  "key" VARCHAR(255) NOT NULL,
  "filename" VARCHAR(255) NOT NULL,
  "content_type" VARCHAR(255),
  "metadata" TEXT,
  "byte_size" BIGINT NOT NULL,
  "checksum" VARCHAR(255),
  "created_at" TIMESTAMP NOT NULL,
  "service_name" VARCHAR(255) NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key");

-- Table: active_storage_variant_records
CREATE TABLE IF NOT EXISTS "active_storage_variant_records" (
  "id" BIGSERIAL PRIMARY KEY,
  "blob_id" BIGINT NOT NULL,
  "variation_digest" VARCHAR(255) NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest");

-- Table: agent_bot_inboxes
CREATE TABLE IF NOT EXISTS "agent_bot_inboxes" (
  "id" BIGSERIAL PRIMARY KEY,
  "inbox_id" INTEGER,
  "agent_bot_id" INTEGER,
  "status" INTEGER DEFAULT 0,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "account_id" INTEGER
);

-- Table: agent_bots
CREATE TABLE IF NOT EXISTS "agent_bots" (
  "id" BIGSERIAL PRIMARY KEY,
  "name" VARCHAR(255),
  "description" VARCHAR(255),
  "outgoing_url" VARCHAR(255),
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "account_id" BIGINT,
  "bot_type" INTEGER DEFAULT 0,
  "bot_config" JSONB DEFAULT '{}'
);
CREATE INDEX IF NOT EXISTS "index_agent_bots_on_account_id" ON "agent_bots" ("account_id");

-- Table: agent_capacity_policies
CREATE TABLE IF NOT EXISTS "agent_capacity_policies" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" BIGINT NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "exclusion_rules" JSONB DEFAULT '{}' NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_agent_capacity_policies_on_account_id" ON "agent_capacity_policies" ("account_id");

-- Table: applied_slas
CREATE TABLE IF NOT EXISTS "applied_slas" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" BIGINT NOT NULL,
  "sla_policy_id" BIGINT NOT NULL,
  "conversation_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "sla_status" INTEGER DEFAULT 0
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_applied_slas_on_account_sla_policy_conversation" ON "applied_slas" ("account_id", "sla_policy_id", "conversation_id");
CREATE INDEX IF NOT EXISTS "index_applied_slas_on_account_id" ON "applied_slas" ("account_id");
CREATE INDEX IF NOT EXISTS "index_applied_slas_on_conversation_id" ON "applied_slas" ("conversation_id");
CREATE INDEX IF NOT EXISTS "index_applied_slas_on_sla_policy_id" ON "applied_slas" ("sla_policy_id");

-- Table: articles
CREATE TABLE IF NOT EXISTS "articles" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" INTEGER NOT NULL,
  "portal_id" INTEGER NOT NULL,
  "category_id" INTEGER,
  "folder_id" INTEGER,
  "title" VARCHAR(255),
  "description" TEXT,
  "content" TEXT,
  "status" INTEGER,
  "views" INTEGER,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "author_id" BIGINT,
  "associated_article_id" BIGINT,
  "meta" JSONB DEFAULT '{}',
  "slug" VARCHAR(255) NOT NULL,
  "position" INTEGER,
  "locale" VARCHAR(255) DEFAULT 'en' NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_articles_on_account_id" ON "articles" ("account_id");
CREATE INDEX IF NOT EXISTS "index_articles_on_associated_article_id" ON "articles" ("associated_article_id");
CREATE INDEX IF NOT EXISTS "index_articles_on_author_id" ON "articles" ("author_id");
CREATE INDEX IF NOT EXISTS "index_articles_on_portal_id" ON "articles" ("portal_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_articles_on_slug" ON "articles" ("slug");
CREATE INDEX IF NOT EXISTS "index_articles_on_status" ON "articles" ("status");
CREATE INDEX IF NOT EXISTS "index_articles_on_views" ON "articles" ("views");

-- Table: assignment_policies
CREATE TABLE IF NOT EXISTS "assignment_policies" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" BIGINT NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "assignment_order" INTEGER DEFAULT 0 NOT NULL,
  "conversation_priority" INTEGER DEFAULT 0 NOT NULL,
  "fair_distribution_limit" INTEGER DEFAULT 100 NOT NULL,
  "fair_distribution_window" INTEGER DEFAULT 3600 NOT NULL,
  "enabled" BOOLEAN DEFAULT TRUE NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_assignment_policies_on_account_id_and_name" ON "assignment_policies" ("account_id", "name");
CREATE INDEX IF NOT EXISTS "index_assignment_policies_on_account_id" ON "assignment_policies" ("account_id");
CREATE INDEX IF NOT EXISTS "index_assignment_policies_on_enabled" ON "assignment_policies" ("enabled");

-- Table: attachments
CREATE TABLE IF NOT EXISTS "attachments" (
  "id" SERIAL PRIMARY KEY,
  "file_type" INTEGER DEFAULT 0,
  "external_url" VARCHAR(255),
  "coordinates_lat" FLOAT DEFAULT 0.0,
  "coordinates_long" FLOAT DEFAULT 0.0,
  "message_id" INTEGER NOT NULL,
  "account_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "fallback_title" VARCHAR(255),
  "extension" VARCHAR(255),
  "meta" JSONB DEFAULT '{}'
);
CREATE INDEX IF NOT EXISTS "index_attachments_on_account_id" ON "attachments" ("account_id");
CREATE INDEX IF NOT EXISTS "index_attachments_on_message_id" ON "attachments" ("message_id");

-- Table: audits
CREATE TABLE IF NOT EXISTS "audits" (
  "id" BIGSERIAL PRIMARY KEY,
  "auditable_id" BIGINT,
  "auditable_type" VARCHAR(255),
  "associated_id" BIGINT,
  "associated_type" VARCHAR(255),
  "user_id" BIGINT,
  "user_type" VARCHAR(255),
  "username" VARCHAR(255),
  "action" VARCHAR(255),
  "audited_changes" JSONB,
  "version" INTEGER DEFAULT 0,
  "comment" VARCHAR(255),
  "remote_address" VARCHAR(255),
  "request_uuid" VARCHAR(255),
  "created_at" TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "associated_index" ON "audits" ("associated_type", "associated_id");
CREATE INDEX IF NOT EXISTS "auditable_index" ON "audits" ("auditable_type", "auditable_id", "version");
CREATE INDEX IF NOT EXISTS "index_audits_on_created_at" ON "audits" ("created_at");
CREATE INDEX IF NOT EXISTS "index_audits_on_request_uuid" ON "audits" ("request_uuid");
CREATE INDEX IF NOT EXISTS "user_index" ON "audits" ("user_id", "user_type");

-- Table: automation_rules
CREATE TABLE IF NOT EXISTS "automation_rules" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" BIGINT NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "event_name" VARCHAR(255) NOT NULL,
  "conditions" JSONB DEFAULT '{}' NOT NULL,
  "actions" JSONB DEFAULT '{}' NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "active" BOOLEAN DEFAULT TRUE NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_automation_rules_on_account_id" ON "automation_rules" ("account_id");

-- Table: campaigns
CREATE TABLE IF NOT EXISTS "campaigns" (
  "id" BIGSERIAL PRIMARY KEY,
  "display_id" INTEGER NOT NULL,
  "title" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "message" TEXT NOT NULL,
  "sender_id" INTEGER,
  "enabled" BOOLEAN DEFAULT TRUE,
  "account_id" BIGINT NOT NULL,
  "inbox_id" BIGINT NOT NULL,
  "trigger_rules" JSONB DEFAULT '{}',
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "campaign_type" INTEGER DEFAULT 0 NOT NULL,
  "campaign_status" INTEGER DEFAULT 0 NOT NULL,
  "audience" JSONB DEFAULT '[]',
  "scheduled_at" TIMESTAMP,
  "trigger_only_during_business_hours" BOOLEAN DEFAULT FALSE,
  "template_params" JSONB
);
CREATE INDEX IF NOT EXISTS "index_campaigns_on_account_id" ON "campaigns" ("account_id");
CREATE INDEX IF NOT EXISTS "index_campaigns_on_campaign_status" ON "campaigns" ("campaign_status");
CREATE INDEX IF NOT EXISTS "index_campaigns_on_campaign_type" ON "campaigns" ("campaign_type");
CREATE INDEX IF NOT EXISTS "index_campaigns_on_inbox_id" ON "campaigns" ("inbox_id");
CREATE INDEX IF NOT EXISTS "index_campaigns_on_scheduled_at" ON "campaigns" ("scheduled_at");

-- Table: canned_responses
CREATE TABLE IF NOT EXISTS "canned_responses" (
  "id" SERIAL PRIMARY KEY,
  "account_id" INTEGER NOT NULL,
  "short_code" VARCHAR(255),
  "content" TEXT,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);

-- Table: categories
CREATE TABLE IF NOT EXISTS "categories" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" INTEGER NOT NULL,
  "portal_id" INTEGER NOT NULL,
  "name" VARCHAR(255),
  "description" TEXT,
  "position" INTEGER,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "locale" VARCHAR(255) DEFAULT 'en',
  "slug" VARCHAR(255) NOT NULL,
  "parent_category_id" BIGINT,
  "associated_category_id" BIGINT,
  "icon" VARCHAR(255) DEFAULT ''
);
CREATE INDEX IF NOT EXISTS "index_categories_on_associated_category_id" ON "categories" ("associated_category_id");
CREATE INDEX IF NOT EXISTS "index_categories_on_locale_and_account_id" ON "categories" ("locale", "account_id");
CREATE INDEX IF NOT EXISTS "index_categories_on_locale" ON "categories" ("locale");
CREATE INDEX IF NOT EXISTS "index_categories_on_parent_category_id" ON "categories" ("parent_category_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_categories_on_slug_and_locale_and_portal_id" ON "categories" ("slug", "locale", "portal_id");

-- Table: channel_api
CREATE TABLE IF NOT EXISTS "channel_api" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" INTEGER NOT NULL,
  "webhook_url" VARCHAR(255),
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "identifier" VARCHAR(255),
  "hmac_token" VARCHAR(255),
  "hmac_mandatory" BOOLEAN DEFAULT FALSE,
  "additional_attributes" JSONB DEFAULT '{}'
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_api_on_hmac_token" ON "channel_api" ("hmac_token");
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_api_on_identifier" ON "channel_api" ("identifier");

-- Table: channel_email
CREATE TABLE IF NOT EXISTS "channel_email" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" INTEGER NOT NULL,
  "email" VARCHAR(255) NOT NULL,
  "forward_to_email" VARCHAR(255) NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "imap_enabled" BOOLEAN DEFAULT FALSE,
  "imap_address" VARCHAR(255) DEFAULT '',
  "imap_port" INTEGER DEFAULT 0,
  "imap_login" VARCHAR(255) DEFAULT '',
  "imap_password" VARCHAR(255) DEFAULT '',
  "imap_enable_ssl" BOOLEAN DEFAULT TRUE,
  "smtp_enabled" BOOLEAN DEFAULT FALSE,
  "smtp_address" VARCHAR(255) DEFAULT '',
  "smtp_port" INTEGER DEFAULT 0,
  "smtp_login" VARCHAR(255) DEFAULT '',
  "smtp_password" VARCHAR(255) DEFAULT '',
  "smtp_domain" VARCHAR(255) DEFAULT '',
  "smtp_enable_starttls_auto" BOOLEAN DEFAULT TRUE,
  "smtp_authentication" VARCHAR(255) DEFAULT 'login',
  "smtp_openssl_verify_mode" VARCHAR(255) DEFAULT 'none',
  "smtp_enable_ssl_tls" BOOLEAN DEFAULT FALSE,
  "provider_config" JSONB DEFAULT '{}',
  "provider" VARCHAR(255),
  "verified_for_sending" BOOLEAN DEFAULT FALSE NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_email_on_email" ON "channel_email" ("email");
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_email_on_forward_to_email" ON "channel_email" ("forward_to_email");

-- Table: channel_facebook_pages
CREATE TABLE IF NOT EXISTS "channel_facebook_pages" (
  "id" SERIAL PRIMARY KEY,
  "page_id" VARCHAR(255) NOT NULL,
  "user_access_token" VARCHAR(255) NOT NULL,
  "page_access_token" VARCHAR(255) NOT NULL,
  "account_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "instagram_id" VARCHAR(255)
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_facebook_pages_on_page_id_and_account_id" ON "channel_facebook_pages" ("page_id", "account_id");
CREATE INDEX IF NOT EXISTS "index_channel_facebook_pages_on_page_id" ON "channel_facebook_pages" ("page_id");

-- Table: channel_instagram
CREATE TABLE IF NOT EXISTS "channel_instagram" (
  "id" BIGSERIAL PRIMARY KEY,
  "access_token" VARCHAR(255) NOT NULL,
  "expires_at" TIMESTAMP NOT NULL,
  "account_id" INTEGER NOT NULL,
  "instagram_id" VARCHAR(255) NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_instagram_on_instagram_id" ON "channel_instagram" ("instagram_id");

-- Table: channel_line
CREATE TABLE IF NOT EXISTS "channel_line" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" INTEGER NOT NULL,
  "line_channel_id" VARCHAR(255) NOT NULL,
  "line_channel_secret" VARCHAR(255) NOT NULL,
  "line_channel_token" VARCHAR(255) NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_line_on_line_channel_id" ON "channel_line" ("line_channel_id");

-- Table: channel_sms
CREATE TABLE IF NOT EXISTS "channel_sms" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" INTEGER NOT NULL,
  "phone_number" VARCHAR(255) NOT NULL,
  "provider" VARCHAR(255) DEFAULT 'default',
  "provider_config" JSONB DEFAULT '{}',
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_sms_on_phone_number" ON "channel_sms" ("phone_number");

-- Table: channel_telegram
CREATE TABLE IF NOT EXISTS "channel_telegram" (
  "id" BIGSERIAL PRIMARY KEY,
  "bot_name" VARCHAR(255),
  "account_id" INTEGER NOT NULL,
  "bot_token" VARCHAR(255) NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_telegram_on_bot_token" ON "channel_telegram" ("bot_token");

-- Table: channel_tiktok
CREATE TABLE IF NOT EXISTS "channel_tiktok" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" INTEGER NOT NULL,
  "business_id" VARCHAR(255) NOT NULL,
  "access_token" VARCHAR(255) NOT NULL,
  "expires_at" TIMESTAMP NOT NULL,
  "refresh_token" VARCHAR(255) NOT NULL,
  "refresh_token_expires_at" TIMESTAMP NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_tiktok_on_business_id" ON "channel_tiktok" ("business_id");

-- Table: channel_twilio_sms
CREATE TABLE IF NOT EXISTS "channel_twilio_sms" (
  "id" BIGSERIAL PRIMARY KEY,
  "phone_number" VARCHAR(255),
  "auth_token" VARCHAR(255) NOT NULL,
  "account_sid" VARCHAR(255) NOT NULL,
  "account_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "medium" INTEGER DEFAULT 0,
  "messaging_service_sid" VARCHAR(255),
  "api_key_sid" VARCHAR(255),
  "content_templates" JSONB DEFAULT '{}',
  "content_templates_last_updated" TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_twilio_sms_on_account_sid_and_phone_number" ON "channel_twilio_sms" ("account_sid", "phone_number");
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_twilio_sms_on_messaging_service_sid" ON "channel_twilio_sms" ("messaging_service_sid");
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_twilio_sms_on_phone_number" ON "channel_twilio_sms" ("phone_number");

-- Table: channel_twitter_profiles
CREATE TABLE IF NOT EXISTS "channel_twitter_profiles" (
  "id" BIGSERIAL PRIMARY KEY,
  "profile_id" VARCHAR(255) NOT NULL,
  "twitter_access_token" VARCHAR(255) NOT NULL,
  "twitter_access_token_secret" VARCHAR(255) NOT NULL,
  "account_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "tweets_enabled" BOOLEAN DEFAULT TRUE
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_twitter_profiles_on_account_id_and_profile_id" ON "channel_twitter_profiles" ("account_id", "profile_id");

-- Table: channel_voice
CREATE TABLE IF NOT EXISTS "channel_voice" (
  "id" BIGSERIAL PRIMARY KEY,
  "phone_number" VARCHAR(255) NOT NULL,
  "provider" VARCHAR(255) DEFAULT 'twilio' NOT NULL,
  "provider_config" JSONB NOT NULL,
  "account_id" INTEGER NOT NULL,
  "additional_attributes" JSONB DEFAULT '{}',
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_channel_voice_on_account_id" ON "channel_voice" ("account_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_voice_on_phone_number" ON "channel_voice" ("phone_number");

-- Table: channel_web_widgets
CREATE TABLE IF NOT EXISTS "channel_web_widgets" (
  "id" SERIAL PRIMARY KEY,
  "website_url" VARCHAR(255),
  "account_id" INTEGER,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "website_token" VARCHAR(255),
  "widget_color" VARCHAR(255) DEFAULT '#1f93ff',
  "welcome_title" VARCHAR(255),
  "welcome_tagline" VARCHAR(255),
  "feature_flags" INTEGER DEFAULT 7 NOT NULL,
  "reply_time" INTEGER DEFAULT 0,
  "hmac_token" VARCHAR(255),
  "pre_chat_form_enabled" BOOLEAN DEFAULT FALSE,
  "pre_chat_form_options" JSONB DEFAULT '{}',
  "hmac_mandatory" BOOLEAN DEFAULT FALSE,
  "continuity_via_email" BOOLEAN DEFAULT TRUE NOT NULL,
  "allowed_domains" TEXT DEFAULT ''
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_web_widgets_on_hmac_token" ON "channel_web_widgets" ("hmac_token");
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_web_widgets_on_website_token" ON "channel_web_widgets" ("website_token");

-- Table: channel_whatsapp
CREATE TABLE IF NOT EXISTS "channel_whatsapp" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" INTEGER NOT NULL,
  "phone_number" VARCHAR(255) NOT NULL,
  "provider" VARCHAR(255) DEFAULT 'default',
  "provider_config" JSONB DEFAULT '{}',
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "message_templates" JSONB DEFAULT '{}',
  "message_templates_last_updated" TIMESTAMP
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_channel_whatsapp_on_phone_number" ON "channel_whatsapp" ("phone_number");

-- Table: companies
CREATE TABLE IF NOT EXISTS "companies" (
  "id" BIGSERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "domain" VARCHAR(255),
  "description" TEXT,
  "account_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "contacts_count" INTEGER DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_companies_on_account_and_domain" ON "companies" ("account_id", "domain") WHERE (domain IS NOT NULL);
CREATE INDEX IF NOT EXISTS "index_companies_on_account_id" ON "companies" ("account_id");
CREATE INDEX IF NOT EXISTS "index_companies_on_name_and_account_id" ON "companies" ("name", "account_id");

-- Table: contact_inboxes
CREATE TABLE IF NOT EXISTS "contact_inboxes" (
  "id" BIGSERIAL PRIMARY KEY,
  "contact_id" BIGINT,
  "inbox_id" BIGINT,
  "source_id" TEXT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "hmac_verified" BOOLEAN DEFAULT FALSE,
  "pubsub_token" VARCHAR(255)
);
CREATE INDEX IF NOT EXISTS "index_contact_inboxes_on_contact_id" ON "contact_inboxes" ("contact_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_contact_inboxes_on_inbox_id_and_source_id" ON "contact_inboxes" ("inbox_id", "source_id");
CREATE INDEX IF NOT EXISTS "index_contact_inboxes_on_inbox_id" ON "contact_inboxes" ("inbox_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_contact_inboxes_on_pubsub_token" ON "contact_inboxes" ("pubsub_token");
CREATE INDEX IF NOT EXISTS "index_contact_inboxes_on_source_id" ON "contact_inboxes" ("source_id");

-- Table: contacts
CREATE TABLE IF NOT EXISTS "contacts" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255) DEFAULT '',
  "email" VARCHAR(255),
  "phone_number" VARCHAR(255),
  "account_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "additional_attributes" JSONB DEFAULT '{}',
  "identifier" VARCHAR(255),
  "custom_attributes" JSONB DEFAULT '{}',
  "last_activity_at" TIMESTAMP,
  "contact_type" INTEGER DEFAULT 0,
  "middle_name" VARCHAR(255) DEFAULT '',
  "last_name" VARCHAR(255) DEFAULT '',
  "location" VARCHAR(255) DEFAULT '',
  "country_code" VARCHAR(255) DEFAULT '',
  "blocked" BOOLEAN DEFAULT FALSE NOT NULL,
  "company_id" BIGINT
);
CREATE INDEX IF NOT EXISTS "index_contacts_on_lower_email_account_id" ON "contacts" (lower((email)::text), account_id);
CREATE INDEX IF NOT EXISTS "index_contacts_on_account_id_and_contact_type" ON "contacts" ("account_id", "contact_type");
CREATE INDEX IF NOT EXISTS "index_contacts_on_nonempty_fields" ON "contacts" ("account_id", "email", "phone_number", "identifier") WHERE (((email)::text <> ''::text) OR ((phone_number)::text <> ''::text) OR ((identifier)::text <> ''::text));
CREATE INDEX IF NOT EXISTS "index_contacts_on_account_id_and_last_activity_at" ON "contacts" ("account_id", "last_activity_at" DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS "index_contacts_on_account_id" ON "contacts" ("account_id");
CREATE INDEX IF NOT EXISTS "index_resolved_contact_account_id" ON "contacts" ("account_id") WHERE (((email)::text <> ''::text) OR ((phone_number)::text <> ''::text) OR ((identifier)::text <> ''::text));
CREATE INDEX IF NOT EXISTS "index_contacts_on_blocked" ON "contacts" ("blocked");
CREATE INDEX IF NOT EXISTS "index_contacts_on_company_id" ON "contacts" ("company_id");
CREATE UNIQUE INDEX IF NOT EXISTS "uniq_email_per_account_contact" ON "contacts" ("email", "account_id");
CREATE UNIQUE INDEX IF NOT EXISTS "uniq_identifier_per_account_contact" ON "contacts" ("identifier", "account_id");
CREATE INDEX IF NOT EXISTS "index_contacts_on_name_email_phone_number_identifier" ON "contacts" USING gin ("name" gin_trgm_ops, "email" gin_trgm_ops, "phone_number" gin_trgm_ops, "identifier" gin_trgm_ops);
CREATE INDEX IF NOT EXISTS "index_contacts_on_phone_number_and_account_id" ON "contacts" ("phone_number", "account_id");

-- Table: conversation_participants
CREATE TABLE IF NOT EXISTS "conversation_participants" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL,
  "conversation_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_conversation_participants_on_account_id" ON "conversation_participants" ("account_id");
CREATE INDEX IF NOT EXISTS "index_conversation_participants_on_conversation_id" ON "conversation_participants" ("conversation_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_conversation_participants_on_user_id_and_conversation_id" ON "conversation_participants" ("user_id", "conversation_id");
CREATE INDEX IF NOT EXISTS "index_conversation_participants_on_user_id" ON "conversation_participants" ("user_id");

-- Table: conversations
CREATE TABLE IF NOT EXISTS "conversations" (
  "id" SERIAL PRIMARY KEY,
  "account_id" INTEGER NOT NULL,
  "inbox_id" INTEGER NOT NULL,
  "status" INTEGER DEFAULT 0 NOT NULL,
  "assignee_id" INTEGER,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "contact_id" BIGINT,
  "display_id" INTEGER NOT NULL,
  "contact_last_seen_at" TIMESTAMP,
  "agent_last_seen_at" TIMESTAMP,
  "additional_attributes" JSONB DEFAULT '{}',
  "contact_inbox_id" BIGINT,
  "uuid" UUID DEFAULT gen_random_uuid() NOT NULL,
  "identifier" VARCHAR(255),
  "last_activity_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "team_id" BIGINT,
  "campaign_id" BIGINT,
  "snoozed_until" TIMESTAMP,
  "custom_attributes" JSONB DEFAULT '{}',
  "assignee_last_seen_at" TIMESTAMP,
  "first_reply_created_at" TIMESTAMP,
  "priority" INTEGER,
  "sla_policy_id" BIGINT,
  "waiting_since" TIMESTAMP,
  "cached_label_list" TEXT,
  "assignee_agent_bot_id" BIGINT
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_conversations_on_account_id_and_display_id" ON "conversations" ("account_id", "display_id");
CREATE INDEX IF NOT EXISTS "index_conversations_on_id_and_account_id" ON "conversations" ("account_id", "id");
CREATE INDEX IF NOT EXISTS "conv_acid_inbid_stat_asgnid_idx" ON "conversations" ("account_id", "inbox_id", "status", "assignee_id");
CREATE INDEX IF NOT EXISTS "index_conversations_on_account_id" ON "conversations" ("account_id");
CREATE INDEX IF NOT EXISTS "index_conversations_on_assignee_id_and_account_id" ON "conversations" ("assignee_id", "account_id");
CREATE INDEX IF NOT EXISTS "index_conversations_on_campaign_id" ON "conversations" ("campaign_id");
CREATE INDEX IF NOT EXISTS "index_conversations_on_contact_id" ON "conversations" ("contact_id");
CREATE INDEX IF NOT EXISTS "index_conversations_on_contact_inbox_id" ON "conversations" ("contact_inbox_id");
CREATE INDEX IF NOT EXISTS "index_conversations_on_first_reply_created_at" ON "conversations" ("first_reply_created_at");
CREATE INDEX IF NOT EXISTS "index_conversations_on_identifier_and_account_id" ON "conversations" ("identifier", "account_id");
CREATE INDEX IF NOT EXISTS "index_conversations_on_inbox_id" ON "conversations" ("inbox_id");
CREATE INDEX IF NOT EXISTS "index_conversations_on_priority" ON "conversations" ("priority");
CREATE INDEX IF NOT EXISTS "index_conversations_on_status_and_account_id" ON "conversations" ("status", "account_id");
CREATE INDEX IF NOT EXISTS "index_conversations_on_status_and_priority" ON "conversations" ("status", "priority");
CREATE INDEX IF NOT EXISTS "index_conversations_on_team_id" ON "conversations" ("team_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_conversations_on_uuid" ON "conversations" ("uuid");
CREATE INDEX IF NOT EXISTS "index_conversations_on_waiting_since" ON "conversations" ("waiting_since");

-- Table: csat_survey_responses
CREATE TABLE IF NOT EXISTS "csat_survey_responses" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" BIGINT NOT NULL,
  "conversation_id" BIGINT NOT NULL,
  "message_id" BIGINT NOT NULL,
  "rating" INTEGER NOT NULL,
  "feedback_message" TEXT,
  "contact_id" BIGINT NOT NULL,
  "assigned_agent_id" BIGINT,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "csat_review_notes" TEXT,
  "review_notes_updated_at" TIMESTAMP,
  "review_notes_updated_by_id" BIGINT
);
CREATE INDEX IF NOT EXISTS "index_csat_survey_responses_on_account_id" ON "csat_survey_responses" ("account_id");
CREATE INDEX IF NOT EXISTS "index_csat_survey_responses_on_assigned_agent_id" ON "csat_survey_responses" ("assigned_agent_id");
CREATE INDEX IF NOT EXISTS "index_csat_survey_responses_on_contact_id" ON "csat_survey_responses" ("contact_id");
CREATE INDEX IF NOT EXISTS "index_csat_survey_responses_on_conversation_id" ON "csat_survey_responses" ("conversation_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_csat_survey_responses_on_message_id" ON "csat_survey_responses" ("message_id");
CREATE INDEX IF NOT EXISTS "index_csat_survey_responses_on_review_notes_updated_by_id" ON "csat_survey_responses" ("review_notes_updated_by_id");

-- Table: custom_attribute_definitions
CREATE TABLE IF NOT EXISTS "custom_attribute_definitions" (
  "id" BIGSERIAL PRIMARY KEY,
  "attribute_display_name" VARCHAR(255),
  "attribute_key" VARCHAR(255),
  "attribute_display_type" INTEGER DEFAULT 0,
  "default_value" INTEGER,
  "attribute_model" INTEGER DEFAULT 0,
  "account_id" BIGINT,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "attribute_description" TEXT,
  "attribute_values" JSONB DEFAULT '[]',
  "regex_pattern" VARCHAR(255),
  "regex_cue" VARCHAR(255)
);
CREATE INDEX IF NOT EXISTS "index_custom_attribute_definitions_on_account_id" ON "custom_attribute_definitions" ("account_id");
CREATE UNIQUE INDEX IF NOT EXISTS "attribute_key_model_index" ON "custom_attribute_definitions" ("attribute_key", "attribute_model", "account_id");

-- Table: custom_filters
CREATE TABLE IF NOT EXISTS "custom_filters" (
  "id" BIGSERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "filter_type" INTEGER DEFAULT 0 NOT NULL,
  "query" JSONB DEFAULT '{}' NOT NULL,
  "account_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_custom_filters_on_account_id" ON "custom_filters" ("account_id");
CREATE INDEX IF NOT EXISTS "index_custom_filters_on_user_id" ON "custom_filters" ("user_id");

-- Table: custom_roles
CREATE TABLE IF NOT EXISTS "custom_roles" (
  "id" BIGSERIAL PRIMARY KEY,
  "name" VARCHAR(255),
  "description" VARCHAR(255),
  "account_id" BIGINT NOT NULL,
  "permissions" TEXT[] DEFAULT '{}',
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_custom_roles_on_account_id" ON "custom_roles" ("account_id");

-- Table: dashboard_apps
CREATE TABLE IF NOT EXISTS "dashboard_apps" (
  "id" BIGSERIAL PRIMARY KEY,
  "title" VARCHAR(255) NOT NULL,
  "content" JSONB DEFAULT '[]',
  "account_id" BIGINT NOT NULL,
  "user_id" BIGINT,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_dashboard_apps_on_account_id" ON "dashboard_apps" ("account_id");
CREATE INDEX IF NOT EXISTS "index_dashboard_apps_on_user_id" ON "dashboard_apps" ("user_id");

-- Table: data_imports
CREATE TABLE IF NOT EXISTS "data_imports" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" BIGINT NOT NULL,
  "data_type" VARCHAR(255) NOT NULL,
  "status" INTEGER DEFAULT 0 NOT NULL,
  "processing_errors" TEXT,
  "total_records" INTEGER,
  "processed_records" INTEGER,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_data_imports_on_account_id" ON "data_imports" ("account_id");

-- Table: email_templates
CREATE TABLE IF NOT EXISTS "email_templates" (
  "id" BIGSERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "body" TEXT NOT NULL,
  "account_id" INTEGER,
  "template_type" INTEGER DEFAULT 1,
  "locale" INTEGER DEFAULT 0 NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_email_templates_on_name_and_account_id" ON "email_templates" ("name", "account_id");

-- Table: folders
CREATE TABLE IF NOT EXISTS "folders" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" INTEGER NOT NULL,
  "category_id" INTEGER NOT NULL,
  "name" VARCHAR(255),
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);

-- Table: inbox_assignment_policies
CREATE TABLE IF NOT EXISTS "inbox_assignment_policies" (
  "id" BIGSERIAL PRIMARY KEY,
  "inbox_id" BIGINT NOT NULL,
  "assignment_policy_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_inbox_assignment_policies_on_assignment_policy_id" ON "inbox_assignment_policies" ("assignment_policy_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_inbox_assignment_policies_on_inbox_id" ON "inbox_assignment_policies" ("inbox_id");

-- Table: inbox_capacity_limits
CREATE TABLE IF NOT EXISTS "inbox_capacity_limits" (
  "id" BIGSERIAL PRIMARY KEY,
  "agent_capacity_policy_id" BIGINT NOT NULL,
  "inbox_id" BIGINT NOT NULL,
  "conversation_limit" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "idx_on_agent_capacity_policy_id_inbox_id_71c7ec4caf" ON "inbox_capacity_limits" ("agent_capacity_policy_id", "inbox_id");
CREATE INDEX IF NOT EXISTS "index_inbox_capacity_limits_on_agent_capacity_policy_id" ON "inbox_capacity_limits" ("agent_capacity_policy_id");
CREATE INDEX IF NOT EXISTS "index_inbox_capacity_limits_on_inbox_id" ON "inbox_capacity_limits" ("inbox_id");

-- Table: inbox_members
CREATE TABLE IF NOT EXISTS "inbox_members" (
  "id" SERIAL PRIMARY KEY,
  "user_id" INTEGER NOT NULL,
  "inbox_id" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_inbox_members_on_inbox_id_and_user_id" ON "inbox_members" ("inbox_id", "user_id");
CREATE INDEX IF NOT EXISTS "index_inbox_members_on_inbox_id" ON "inbox_members" ("inbox_id");

-- Table: inboxes
CREATE TABLE IF NOT EXISTS "inboxes" (
  "id" SERIAL PRIMARY KEY,
  "channel_id" INTEGER NOT NULL,
  "account_id" INTEGER NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "channel_type" VARCHAR(255),
  "enable_auto_assignment" BOOLEAN DEFAULT TRUE,
  "greeting_enabled" BOOLEAN DEFAULT FALSE,
  "greeting_message" VARCHAR(255),
  "email_address" VARCHAR(255),
  "working_hours_enabled" BOOLEAN DEFAULT FALSE,
  "out_of_office_message" VARCHAR(255),
  "timezone" VARCHAR(255) DEFAULT 'UTC',
  "enable_email_collect" BOOLEAN DEFAULT TRUE,
  "csat_survey_enabled" BOOLEAN DEFAULT FALSE,
  "allow_messages_after_resolved" BOOLEAN DEFAULT TRUE,
  "auto_assignment_config" JSONB DEFAULT '{}',
  "lock_to_single_conversation" BOOLEAN DEFAULT FALSE NOT NULL,
  "portal_id" BIGINT,
  "sender_name_type" INTEGER DEFAULT 0 NOT NULL,
  "business_name" VARCHAR(255),
  "csat_config" JSONB DEFAULT '{}' NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_inboxes_on_account_id" ON "inboxes" ("account_id");
CREATE INDEX IF NOT EXISTS "index_inboxes_on_channel_id_and_channel_type" ON "inboxes" ("channel_id", "channel_type");
CREATE INDEX IF NOT EXISTS "index_inboxes_on_portal_id" ON "inboxes" ("portal_id");

-- Table: installation_configs
CREATE TABLE IF NOT EXISTS "installation_configs" (
  "id" BIGSERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "serialized_value" JSONB DEFAULT '{}' NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "locked" BOOLEAN DEFAULT TRUE NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_installation_configs_on_name_and_created_at" ON "installation_configs" ("name", "created_at");
CREATE UNIQUE INDEX IF NOT EXISTS "index_installation_configs_on_name" ON "installation_configs" ("name");

-- Table: integrations_hooks
CREATE TABLE IF NOT EXISTS "integrations_hooks" (
  "id" BIGSERIAL PRIMARY KEY,
  "status" INTEGER DEFAULT 1,
  "inbox_id" INTEGER,
  "account_id" INTEGER,
  "app_id" VARCHAR(255),
  "hook_type" INTEGER DEFAULT 0,
  "reference_id" VARCHAR(255),
  "access_token" VARCHAR(255),
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "settings" JSONB DEFAULT '{}'
);

-- Table: labels
CREATE TABLE IF NOT EXISTS "labels" (
  "id" BIGSERIAL PRIMARY KEY,
  "title" VARCHAR(255),
  "description" TEXT,
  "color" VARCHAR(255) DEFAULT '#1f93ff' NOT NULL,
  "show_on_sidebar" BOOLEAN,
  "account_id" BIGINT,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_labels_on_account_id" ON "labels" ("account_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_labels_on_title_and_account_id" ON "labels" ("title", "account_id");

-- Table: leaves
CREATE TABLE IF NOT EXISTS "leaves" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL,
  "start_date" DATE NOT NULL,
  "end_date" DATE NOT NULL,
  "leave_type" INTEGER DEFAULT 0 NOT NULL,
  "status" INTEGER DEFAULT 0 NOT NULL,
  "reason" TEXT,
  "approved_by_id" BIGINT,
  "approved_at" TIMESTAMP,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_leaves_on_account_id_and_status" ON "leaves" ("account_id", "status");
CREATE INDEX IF NOT EXISTS "index_leaves_on_account_id" ON "leaves" ("account_id");
CREATE INDEX IF NOT EXISTS "index_leaves_on_approved_by_id" ON "leaves" ("approved_by_id");
CREATE INDEX IF NOT EXISTS "index_leaves_on_user_id" ON "leaves" ("user_id");

-- Table: macros
CREATE TABLE IF NOT EXISTS "macros" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" BIGINT NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "visibility" INTEGER DEFAULT 0,
  "created_by_id" BIGINT,
  "updated_by_id" BIGINT,
  "actions" JSONB DEFAULT '{}' NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_macros_on_account_id" ON "macros" ("account_id");

-- Table: mentions
CREATE TABLE IF NOT EXISTS "mentions" (
  "id" BIGSERIAL PRIMARY KEY,
  "user_id" BIGINT NOT NULL,
  "conversation_id" BIGINT NOT NULL,
  "account_id" BIGINT NOT NULL,
  "mentioned_at" TIMESTAMP NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_mentions_on_account_id" ON "mentions" ("account_id");
CREATE INDEX IF NOT EXISTS "index_mentions_on_conversation_id" ON "mentions" ("conversation_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_mentions_on_user_id_and_conversation_id" ON "mentions" ("user_id", "conversation_id");
CREATE INDEX IF NOT EXISTS "index_mentions_on_user_id" ON "mentions" ("user_id");

-- Table: messages
CREATE TABLE IF NOT EXISTS "messages" (
  "id" SERIAL PRIMARY KEY,
  "content" TEXT,
  "account_id" INTEGER NOT NULL,
  "inbox_id" INTEGER NOT NULL,
  "conversation_id" INTEGER NOT NULL,
  "message_type" INTEGER NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "private" BOOLEAN DEFAULT FALSE NOT NULL,
  "status" INTEGER DEFAULT 0,
  "source_id" TEXT,
  "content_type" INTEGER DEFAULT 0 NOT NULL,
  "content_attributes" JSON DEFAULT '{}',
  "sender_type" VARCHAR(255),
  "sender_id" BIGINT,
  "external_source_ids" JSONB DEFAULT '{}',
  "additional_attributes" JSONB DEFAULT '{}',
  "processed_message_content" TEXT,
  "sentiment" JSONB DEFAULT '{}'
);
CREATE INDEX IF NOT EXISTS "index_messages_on_additional_attributes_campaign_id" ON "messages" USING gin ((additional_attributes -> 'campaign_id'::text));
CREATE INDEX IF NOT EXISTS "idx_messages_account_content_created" ON "messages" ("account_id", "content_type", "created_at");
CREATE INDEX IF NOT EXISTS "index_messages_on_account_created_type" ON "messages" ("account_id", "created_at", "message_type");
CREATE INDEX IF NOT EXISTS "index_messages_on_account_id_and_inbox_id" ON "messages" ("account_id", "inbox_id");
CREATE INDEX IF NOT EXISTS "index_messages_on_account_id" ON "messages" ("account_id");
CREATE INDEX IF NOT EXISTS "index_messages_on_content" ON "messages" USING gin ("content" gin_trgm_ops);
CREATE INDEX IF NOT EXISTS "index_messages_on_conversation_account_type_created" ON "messages" ("conversation_id", "account_id", "message_type", "created_at");
CREATE INDEX IF NOT EXISTS "index_messages_on_conversation_id" ON "messages" ("conversation_id");
CREATE INDEX IF NOT EXISTS "index_messages_on_created_at" ON "messages" ("created_at");
CREATE INDEX IF NOT EXISTS "index_messages_on_inbox_id" ON "messages" ("inbox_id");
CREATE INDEX IF NOT EXISTS "index_messages_on_sender_type_and_sender_id" ON "messages" ("sender_type", "sender_id");
CREATE INDEX IF NOT EXISTS "index_messages_on_source_id" ON "messages" ("source_id");

-- Table: notes
CREATE TABLE IF NOT EXISTS "notes" (
  "id" BIGSERIAL PRIMARY KEY,
  "content" TEXT NOT NULL,
  "account_id" BIGINT NOT NULL,
  "contact_id" BIGINT NOT NULL,
  "user_id" BIGINT,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_notes_on_account_id" ON "notes" ("account_id");
CREATE INDEX IF NOT EXISTS "index_notes_on_contact_id" ON "notes" ("contact_id");
CREATE INDEX IF NOT EXISTS "index_notes_on_user_id" ON "notes" ("user_id");

-- Table: notification_settings
CREATE TABLE IF NOT EXISTS "notification_settings" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" INTEGER,
  "user_id" INTEGER,
  "email_flags" INTEGER DEFAULT 0 NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "push_flags" INTEGER DEFAULT 0 NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "by_account_user" ON "notification_settings" ("account_id", "user_id");

-- Table: notification_subscriptions
CREATE TABLE IF NOT EXISTS "notification_subscriptions" (
  "id" BIGSERIAL PRIMARY KEY,
  "user_id" BIGINT NOT NULL,
  "subscription_type" INTEGER NOT NULL,
  "subscription_attributes" JSONB DEFAULT '{}' NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "identifier" TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_notification_subscriptions_on_identifier" ON "notification_subscriptions" ("identifier");
CREATE INDEX IF NOT EXISTS "index_notification_subscriptions_on_user_id" ON "notification_subscriptions" ("user_id");

-- Table: notifications
CREATE TABLE IF NOT EXISTS "notifications" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL,
  "notification_type" INTEGER NOT NULL,
  "primary_actor_type" VARCHAR(255) NOT NULL,
  "primary_actor_id" BIGINT NOT NULL,
  "secondary_actor_type" VARCHAR(255),
  "secondary_actor_id" BIGINT,
  "read_at" TIMESTAMP,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "snoozed_until" TIMESTAMP,
  "last_activity_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "meta" JSONB DEFAULT '{}'
);
CREATE INDEX IF NOT EXISTS "index_notifications_on_account_id" ON "notifications" ("account_id");
CREATE INDEX IF NOT EXISTS "index_notifications_on_last_activity_at" ON "notifications" ("last_activity_at");
CREATE INDEX IF NOT EXISTS "uniq_primary_actor_per_account_notifications" ON "notifications" ("primary_actor_type", "primary_actor_id");
CREATE INDEX IF NOT EXISTS "uniq_secondary_actor_per_account_notifications" ON "notifications" ("secondary_actor_type", "secondary_actor_id");
CREATE INDEX IF NOT EXISTS "idx_notifications_performance" ON "notifications" ("user_id", "account_id", "snoozed_until", "read_at");
CREATE INDEX IF NOT EXISTS "index_notifications_on_user_id" ON "notifications" ("user_id");

-- Table: platform_app_permissibles
CREATE TABLE IF NOT EXISTS "platform_app_permissibles" (
  "id" BIGSERIAL PRIMARY KEY,
  "platform_app_id" BIGINT NOT NULL,
  "permissible_type" VARCHAR(255) NOT NULL,
  "permissible_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_platform_app_permissibles_on_permissibles" ON "platform_app_permissibles" ("permissible_type", "permissible_id");
CREATE UNIQUE INDEX IF NOT EXISTS "unique_permissibles_index" ON "platform_app_permissibles" ("platform_app_id", "permissible_id", "permissible_type");
CREATE INDEX IF NOT EXISTS "index_platform_app_permissibles_on_platform_app_id" ON "platform_app_permissibles" ("platform_app_id");

-- Table: platform_apps
CREATE TABLE IF NOT EXISTS "platform_apps" (
  "id" BIGSERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);

-- Table: portals
CREATE TABLE IF NOT EXISTS "portals" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" INTEGER NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  "slug" VARCHAR(255) NOT NULL,
  "custom_domain" VARCHAR(255),
  "color" VARCHAR(255),
  "homepage_link" VARCHAR(255),
  "page_title" VARCHAR(255),
  "header_text" TEXT,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "config" JSONB DEFAULT '{"allowed_locales": ["en"]}',
  "archived" BOOLEAN DEFAULT FALSE,
  "channel_web_widget_id" BIGINT,
  "ssl_settings" JSONB DEFAULT '{}' NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_portals_on_channel_web_widget_id" ON "portals" ("channel_web_widget_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_portals_on_custom_domain" ON "portals" ("custom_domain");
CREATE UNIQUE INDEX IF NOT EXISTS "index_portals_on_slug" ON "portals" ("slug");

-- Table: portals_members (no primary key)
CREATE TABLE IF NOT EXISTS "portals_members" (
  "portal_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_portals_members_on_portal_id_and_user_id" ON "portals_members" ("portal_id", "user_id");
CREATE INDEX IF NOT EXISTS "index_portals_members_on_portal_id" ON "portals_members" ("portal_id");
CREATE INDEX IF NOT EXISTS "index_portals_members_on_user_id" ON "portals_members" ("user_id");

-- Table: related_categories
CREATE TABLE IF NOT EXISTS "related_categories" (
  "id" BIGSERIAL PRIMARY KEY,
  "category_id" BIGINT,
  "related_category_id" BIGINT,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_related_categories_on_category_id_and_related_category_id" ON "related_categories" ("category_id", "related_category_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_related_categories_on_related_category_id_and_category_id" ON "related_categories" ("related_category_id", "category_id");

-- Table: reporting_events
CREATE TABLE IF NOT EXISTS "reporting_events" (
  "id" BIGSERIAL PRIMARY KEY,
  "name" VARCHAR(255),
  "value" FLOAT,
  "account_id" INTEGER,
  "inbox_id" INTEGER,
  "user_id" INTEGER,
  "conversation_id" INTEGER,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "value_in_business_hours" FLOAT,
  "event_start_time" TIMESTAMP,
  "event_end_time" TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "reporting_events__account_id__name__created_at" ON "reporting_events" ("account_id", "name", "created_at");
CREATE INDEX IF NOT EXISTS "index_reporting_events_for_response_distribution" ON "reporting_events" ("account_id", "name", "inbox_id", "created_at");
CREATE INDEX IF NOT EXISTS "index_reporting_events_on_account_id" ON "reporting_events" ("account_id");
CREATE INDEX IF NOT EXISTS "index_reporting_events_on_conversation_id" ON "reporting_events" ("conversation_id");
CREATE INDEX IF NOT EXISTS "index_reporting_events_on_created_at" ON "reporting_events" ("created_at");
CREATE INDEX IF NOT EXISTS "index_reporting_events_on_inbox_id" ON "reporting_events" ("inbox_id");
CREATE INDEX IF NOT EXISTS "index_reporting_events_on_name" ON "reporting_events" ("name");
CREATE INDEX IF NOT EXISTS "index_reporting_events_on_user_id" ON "reporting_events" ("user_id");

-- Table: reporting_events_rollups
CREATE TABLE IF NOT EXISTS "reporting_events_rollups" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" INTEGER NOT NULL,
  "date" DATE NOT NULL,
  "dimension_type" VARCHAR(255) NOT NULL,
  "dimension_id" BIGINT NOT NULL,
  "metric" VARCHAR(255) NOT NULL,
  "count" BIGINT DEFAULT 0 NOT NULL,
  "sum_value" FLOAT DEFAULT 0.0 NOT NULL,
  "sum_value_business_hours" FLOAT DEFAULT 0.0 NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_rollup_unique_key" ON "reporting_events_rollups" ("account_id", "date", "dimension_type", "dimension_id", "metric");
CREATE INDEX IF NOT EXISTS "index_rollup_summary" ON "reporting_events_rollups" ("account_id", "dimension_type", "date");
CREATE INDEX IF NOT EXISTS "index_rollup_timeseries" ON "reporting_events_rollups" ("account_id", "metric", "date");

-- Table: sla_events
CREATE TABLE IF NOT EXISTS "sla_events" (
  "id" BIGSERIAL PRIMARY KEY,
  "applied_sla_id" BIGINT NOT NULL,
  "conversation_id" BIGINT NOT NULL,
  "account_id" BIGINT NOT NULL,
  "sla_policy_id" BIGINT NOT NULL,
  "inbox_id" BIGINT NOT NULL,
  "event_type" INTEGER,
  "meta" JSONB DEFAULT '{}',
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_sla_events_on_account_id" ON "sla_events" ("account_id");
CREATE INDEX IF NOT EXISTS "index_sla_events_on_applied_sla_id" ON "sla_events" ("applied_sla_id");
CREATE INDEX IF NOT EXISTS "index_sla_events_on_conversation_id" ON "sla_events" ("conversation_id");
CREATE INDEX IF NOT EXISTS "index_sla_events_on_inbox_id" ON "sla_events" ("inbox_id");
CREATE INDEX IF NOT EXISTS "index_sla_events_on_sla_policy_id" ON "sla_events" ("sla_policy_id");

-- Table: sla_policies
CREATE TABLE IF NOT EXISTS "sla_policies" (
  "id" BIGSERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "first_response_time_threshold" FLOAT,
  "next_response_time_threshold" FLOAT,
  "only_during_business_hours" BOOLEAN DEFAULT FALSE,
  "account_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "description" VARCHAR(255),
  "resolution_time_threshold" FLOAT
);
CREATE INDEX IF NOT EXISTS "index_sla_policies_on_account_id" ON "sla_policies" ("account_id");

-- Table: taggings
CREATE TABLE IF NOT EXISTS "taggings" (
  "id" SERIAL PRIMARY KEY,
  "tag_id" INTEGER,
  "taggable_type" VARCHAR(255),
  "taggable_id" INTEGER,
  "tagger_type" VARCHAR(255),
  "tagger_id" INTEGER,
  "context" VARCHAR(128),
  "created_at" TIMESTAMP
);
CREATE INDEX IF NOT EXISTS "index_taggings_on_context" ON "taggings" ("context");
CREATE UNIQUE INDEX IF NOT EXISTS "taggings_idx" ON "taggings" ("tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type");
CREATE INDEX IF NOT EXISTS "index_taggings_on_tag_id" ON "taggings" ("tag_id");
CREATE INDEX IF NOT EXISTS "index_taggings_on_taggable_id_and_taggable_type_and_context" ON "taggings" ("taggable_id", "taggable_type", "context");
CREATE INDEX IF NOT EXISTS "taggings_idy" ON "taggings" ("taggable_id", "taggable_type", "tagger_id", "context");
CREATE INDEX IF NOT EXISTS "index_taggings_on_taggable_id" ON "taggings" ("taggable_id");
CREATE INDEX IF NOT EXISTS "index_taggings_on_taggable_type" ON "taggings" ("taggable_type");
CREATE INDEX IF NOT EXISTS "index_taggings_on_tagger_id_and_tagger_type" ON "taggings" ("tagger_id", "tagger_type");
CREATE INDEX IF NOT EXISTS "index_taggings_on_tagger_id" ON "taggings" ("tagger_id");

-- Table: tags
CREATE TABLE IF NOT EXISTS "tags" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(255),
  "taggings_count" INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS "tags_name_trgm_idx" ON "tags" USING gin (lower((name)::text) gin_trgm_ops);
CREATE UNIQUE INDEX IF NOT EXISTS "index_tags_on_name" ON "tags" ("name");

-- Table: team_members
CREATE TABLE IF NOT EXISTS "team_members" (
  "id" BIGSERIAL PRIMARY KEY,
  "team_id" BIGINT NOT NULL,
  "user_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_team_members_on_team_id_and_user_id" ON "team_members" ("team_id", "user_id");
CREATE INDEX IF NOT EXISTS "index_team_members_on_team_id" ON "team_members" ("team_id");
CREATE INDEX IF NOT EXISTS "index_team_members_on_user_id" ON "team_members" ("user_id");

-- Table: teams
CREATE TABLE IF NOT EXISTS "teams" (
  "id" BIGSERIAL PRIMARY KEY,
  "name" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "allow_auto_assign" BOOLEAN DEFAULT TRUE,
  "account_id" BIGINT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS "index_teams_on_account_id" ON "teams" ("account_id");
CREATE UNIQUE INDEX IF NOT EXISTS "index_teams_on_name_and_account_id" ON "teams" ("name", "account_id");

-- Table: users
CREATE TABLE IF NOT EXISTS "users" (
  "id" SERIAL PRIMARY KEY,
  "provider" VARCHAR(255) DEFAULT 'email' NOT NULL,
  "uid" VARCHAR(255) DEFAULT '' NOT NULL,
  "encrypted_password" VARCHAR(255) DEFAULT '' NOT NULL,
  "reset_password_token" VARCHAR(255),
  "reset_password_sent_at" TIMESTAMP,
  "remember_created_at" TIMESTAMP,
  "sign_in_count" INTEGER DEFAULT 0 NOT NULL,
  "current_sign_in_at" TIMESTAMP,
  "last_sign_in_at" TIMESTAMP,
  "current_sign_in_ip" VARCHAR(255),
  "last_sign_in_ip" VARCHAR(255),
  "confirmation_token" VARCHAR(255),
  "confirmed_at" TIMESTAMP,
  "confirmation_sent_at" TIMESTAMP,
  "unconfirmed_email" VARCHAR(255),
  "name" VARCHAR(255) NOT NULL,
  "display_name" VARCHAR(255),
  "email" VARCHAR(255),
  "tokens" JSON,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "pubsub_token" VARCHAR(255),
  "availability" INTEGER DEFAULT 0,
  "ui_settings" JSONB DEFAULT '{}',
  "custom_attributes" JSONB DEFAULT '{}',
  "type" VARCHAR(255),
  "message_signature" TEXT,
  "otp_secret" VARCHAR(255),
  "consumed_timestep" INTEGER,
  "otp_required_for_login" BOOLEAN DEFAULT FALSE NOT NULL,
  "otp_backup_codes" TEXT
);
CREATE INDEX IF NOT EXISTS "index_users_on_email" ON "users" ("email");
CREATE INDEX IF NOT EXISTS "index_users_on_otp_required_for_login" ON "users" ("otp_required_for_login");
CREATE UNIQUE INDEX IF NOT EXISTS "index_users_on_otp_secret" ON "users" ("otp_secret");
CREATE UNIQUE INDEX IF NOT EXISTS "index_users_on_pubsub_token" ON "users" ("pubsub_token");
CREATE UNIQUE INDEX IF NOT EXISTS "index_users_on_reset_password_token" ON "users" ("reset_password_token");
CREATE UNIQUE INDEX IF NOT EXISTS "index_users_on_uid_and_provider" ON "users" ("uid", "provider");

-- Table: webhooks
CREATE TABLE IF NOT EXISTS "webhooks" (
  "id" BIGSERIAL PRIMARY KEY,
  "account_id" INTEGER,
  "inbox_id" INTEGER,
  "url" TEXT,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "webhook_type" INTEGER DEFAULT 0,
  "subscriptions" JSONB DEFAULT '["conversation_status_changed","conversation_updated","conversation_created","contact_created","contact_updated","message_created","message_updated","webwidget_triggered"]',
  "name" VARCHAR(255),
  "secret" VARCHAR(255)
);
CREATE UNIQUE INDEX IF NOT EXISTS "index_webhooks_on_account_id_and_url" ON "webhooks" ("account_id", "url");

-- Table: working_hours
CREATE TABLE IF NOT EXISTS "working_hours" (
  "id" BIGSERIAL PRIMARY KEY,
  "inbox_id" BIGINT,
  "account_id" BIGINT,
  "day_of_week" INTEGER NOT NULL,
  "closed_all_day" BOOLEAN DEFAULT FALSE,
  "open_hour" INTEGER,
  "open_minutes" INTEGER,
  "close_hour" INTEGER,
  "close_minutes" INTEGER,
  "created_at" TIMESTAMP NOT NULL,
  "updated_at" TIMESTAMP NOT NULL,
  "open_all_day" BOOLEAN DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS "index_working_hours_on_account_id" ON "working_hours" ("account_id");
CREATE INDEX IF NOT EXISTS "index_working_hours_on_inbox_id" ON "working_hours" ("inbox_id");

-- Triggers
CREATE OR REPLACE FUNCTION accounts_after_insert_row_tr_func()
RETURNS TRIGGER AS $$
BEGIN
  EXECUTE format('CREATE SEQUENCE IF NOT EXISTS conv_dpid_seq_%s', NEW.id);
  EXECUTE format('CREATE SEQUENCE IF NOT EXISTS camp_dpid_seq_%s', NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER accounts_after_insert_row_tr
AFTER INSERT ON "accounts"
FOR EACH ROW EXECUTE FUNCTION accounts_after_insert_row_tr_func();

CREATE OR REPLACE FUNCTION conversations_before_insert_row_tr_func()
RETURNS TRIGGER AS $$
BEGIN
  NEW.display_id := nextval('conv_dpid_seq_' || NEW.account_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER conversations_before_insert_row_tr
BEFORE INSERT ON "conversations"
FOR EACH ROW EXECUTE FUNCTION conversations_before_insert_row_tr_func();

CREATE OR REPLACE FUNCTION campaigns_before_insert_row_tr_func()
RETURNS TRIGGER AS $$
BEGIN
  NEW.display_id := nextval('camp_dpid_seq_' || NEW.account_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER campaigns_before_insert_row_tr
BEFORE INSERT ON "campaigns"
FOR EACH ROW EXECUTE FUNCTION campaigns_before_insert_row_tr_func();
