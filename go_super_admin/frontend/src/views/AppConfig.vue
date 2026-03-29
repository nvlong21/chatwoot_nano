<script setup>
import { ref, watch, computed } from 'vue'
import { useRoute } from 'vue-router'
import client from '../api/client'

const route = useRoute()
const form = ref({})
const saved = ref(false)
const loading = ref(false)
const showSecret = ref({})

// Section metadata: label, description, type (text|secret|boolean)
const SECTION_META = {
  general: {
    label: 'General',
    icon: 'ri-settings-2-line',
    description: 'General settings for your Chatwoot installation.',
    fields: {
      ENABLE_ACCOUNT_SIGNUP:   { label: 'Enable Account Signup',          description: 'Allow users to signup for new accounts.', type: 'boolean' },
      FIREBASE_PROJECT_ID:     { label: 'Firebase Project ID',            description: 'Firebase project ID.', type: 'text' },
      FIREBASE_CREDENTIALS:    { label: 'Firebase Credentials',           description: 'Firebase service account credentials JSON.', type: 'secret' },
      WEBHOOK_TIMEOUT:         { label: 'Webhook Request Timeout (secs)', description: 'Maximum time Chatwoot waits for a webhook response before failing the request.', type: 'text' },
      MAXIMUM_FILE_UPLOAD_SIZE:{ label: 'Attachment Size Limit (MB)',     description: 'Maximum attachment size in MB allowed for uploads.', type: 'text' },
      WIDGET_TOKEN_EXPIRY:     { label: 'Widget Token Expiry (days)',     description: 'Token expiry in days.', type: 'text' },
    },
  },
  email: {
    label: 'Email',
    icon: 'ri-mail-send-fill',
    description: 'Inbound email and sending limit settings.',
    fields: {
      MAILER_INBOUND_EMAIL_DOMAIN:  { label: 'Inbound Email Domain',              description: 'The domain name used for conversation continuity emails (reply+id@domain.com).', type: 'text' },
      ACCOUNT_EMAILS_LIMIT:         { label: 'Account Email Sending Limit (Daily)', description: 'Maximum number of non-channel emails an account can send per day.', type: 'text' },
      ACCOUNT_EMAILS_PLAN_LIMITS:   { label: 'Account Email Plan Limits (Daily)', description: 'Per-plan daily email sending limits as JSON.', type: 'text' },
    },
  },
  facebook: {
    label: 'Messenger',
    icon: 'ri-messenger-line',
    description: 'Facebook Messenger and Meta integration settings.',
    fields: {
      FB_APP_ID:                          { label: 'Facebook App ID',           description: 'Your Facebook App ID from the Meta developer portal.', type: 'text' },
      FB_VERIFY_TOKEN:                    { label: 'Facebook Verify Token',     description: 'The verify token used for Facebook Messenger Webhook.', type: 'secret' },
      FB_APP_SECRET:                      { label: 'Facebook App Secret',       description: 'Your Facebook App Secret from the Meta developer portal.', type: 'secret' },
      IG_VERIFY_TOKEN:                    { label: 'Instagram Verify Token',    description: 'The verify token used for Instagram Webhook.', type: 'secret' },
      FACEBOOK_API_VERSION:               { label: 'Facebook API Version',      description: "Configure if you want a different Facebook API version. Must be prefixed with 'v'.", type: 'text' },
      ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT: { label: 'Enable Human Agent',      description: 'Enable human agent for Messenger channel for longer message back period. Needs additional app approval.', type: 'boolean' },
    },
  },
  instagram: {
    label: 'Instagram',
    icon: 'ri-instagram-line',
    description: 'Instagram channel integration settings.',
    fields: {
      INSTAGRAM_APP_ID:                       { label: 'Instagram App ID',                   description: 'Your Instagram App ID.', type: 'text' },
      INSTAGRAM_APP_SECRET:                   { label: 'Instagram App Secret',               description: 'The App Secret used for Instagram authentication.', type: 'secret' },
      INSTAGRAM_VERIFY_TOKEN:                 { label: 'Instagram Verify Token',             description: 'The verify token used for Instagram Webhook.', type: 'secret' },
      INSTAGRAM_API_VERSION:                  { label: 'Instagram API Version',              description: "Configure if you want a different Instagram API version. Must be prefixed with 'v'.", type: 'text' },
      ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT:   { label: 'Enable Human Agent for Instagram',  description: 'Enable human agent for Instagram channel. Needs additional app approval.', type: 'boolean' },
    },
  },
  tiktok: {
    label: 'TikTok',
    icon: 'ri-tiktok-line',
    description: 'TikTok channel integration settings.',
    fields: {
      TIKTOK_APP_ID:     { label: 'TikTok App ID',      description: 'Your TikTok App ID.', type: 'text' },
      TIKTOK_APP_SECRET: { label: 'TikTok App Secret',  description: 'Your TikTok App Secret.', type: 'secret' },
      TIKTOK_API_VERSION:{ label: 'TikTok API Version', description: "Configure if you want a different TikTok API version. Must be prefixed with 'v'.", type: 'text' },
    },
  },
  google: {
    label: 'Google',
    icon: 'ri-google-line',
    description: 'Google OAuth integration for agent login.',
    fields: {
      GOOGLE_OAUTH_CLIENT_ID:     { label: 'Google OAuth Client ID',     description: 'Google OAuth Client ID for email authentication.', type: 'text' },
      GOOGLE_OAUTH_CLIENT_SECRET: { label: 'Google OAuth Client Secret', description: 'Google OAuth Client Secret for email authentication.', type: 'secret' },
      GOOGLE_OAUTH_REDIRECT_URI:  { label: 'Google OAuth Redirect URI',  description: 'The redirect URI configured in your Google OAuth app.', type: 'text' },
      ENABLE_GOOGLE_OAUTH_LOGIN:  { label: 'Enable Google OAuth Login',  description: 'Show Google OAuth as a login option when credentials are configured.', type: 'boolean' },
    },
  },
  microsoft: {
    label: 'Microsoft',
    icon: 'ri-microsoft-line',
    description: 'Microsoft Azure / Office 365 integration.',
    fields: {
      AZURE_APP_ID:     { label: 'Azure App ID',     description: 'The App ID used to authenticate with customer Microsoft accounts.', type: 'text' },
      AZURE_APP_SECRET: { label: 'Azure App Secret', description: 'Client secret from Azure Active Directory.', type: 'secret' },
    },
  },
  slack: {
    label: 'Slack',
    icon: 'ri-slack-line',
    description: 'Slack integration settings.',
    fields: {
      SLACK_CLIENT_ID:     { label: 'Slack Client ID',     description: 'Slack client ID.', type: 'text' },
      SLACK_CLIENT_SECRET: { label: 'Slack Client Secret', description: 'Slack client secret.', type: 'secret' },
    },
  },
  whatsapp_embedded: {
    label: 'WhatsApp Embedded',
    icon: 'ri-whatsapp-line',
    description: 'WhatsApp Business API embedded signup settings.',
    fields: {
      WHATSAPP_APP_ID:           { label: 'WhatsApp App ID',           description: 'The Facebook App ID for WhatsApp Business API integration.', type: 'text' },
      WHATSAPP_APP_SECRET:       { label: 'WhatsApp App Secret',       description: 'The App Secret for WhatsApp Embedded Signup flow.', type: 'secret' },
      WHATSAPP_CONFIGURATION_ID: { label: 'WhatsApp Configuration ID', description: 'The Configuration ID for WhatsApp Embedded Signup flow.', type: 'text' },
      WHATSAPP_API_VERSION:      { label: 'WhatsApp API Version',      description: "Configure if you want a different WhatsApp API version. Must be prefixed with 'v'.", type: 'text' },
    },
  },
  shopify: {
    label: 'Shopify',
    icon: 'ri-shopping-bag-line',
    description: 'Shopify store integration settings.',
    fields: {
      SHOPIFY_CLIENT_ID:     { label: 'Shopify Client ID',     description: 'The Client ID (API Key) from your Shopify Partner account.', type: 'text' },
      SHOPIFY_CLIENT_SECRET: { label: 'Shopify Client Secret', description: 'The Client Secret (API Secret Key) from your Shopify Partner account.', type: 'secret' },
    },
  },
  notion: {
    label: 'Notion',
    icon: 'ri-notion-line',
    description: 'Notion integration settings.',
    fields: {
      NOTION_CLIENT_ID:     { label: 'Notion Client ID',     description: 'Notion client ID.', type: 'text' },
      NOTION_CLIENT_SECRET: { label: 'Notion Client Secret', description: 'Notion client secret.', type: 'secret' },
    },
  },
  custom_branding: {
    label: 'Custom Branding',
    icon: 'ri-paint-brush-line',
    description: 'Customize branding for your Chatwoot installation.',
    fields: {
      LOGO_THUMBNAIL:   { label: 'Logo Thumbnail',    description: 'URL to your logo thumbnail image.', type: 'text' },
      LOGO:             { label: 'Logo',               description: 'URL to your full logo image.', type: 'text' },
      LOGO_DARK:        { label: 'Logo Dark',          description: 'URL to your dark-mode logo image.', type: 'text' },
      BRAND_NAME:       { label: 'Brand Name',         description: 'Name to display instead of "Chatwoot".', type: 'text' },
      INSTALLATION_NAME:{ label: 'Installation Name',  description: 'Name of this Chatwoot installation.', type: 'text' },
      BRAND_URL:        { label: 'Brand URL',          description: 'Homepage URL for your brand.', type: 'text' },
      WIDGET_BRAND_URL: { label: 'Widget Brand URL',   description: 'Brand URL shown inside the chat widget.', type: 'text' },
      TERMS_URL:        { label: 'Terms URL',          description: 'URL to your Terms of Service page.', type: 'text' },
      PRIVACY_URL:      { label: 'Privacy URL',        description: 'URL to your Privacy Policy page.', type: 'text' },
      DISPLAY_MANIFEST: { label: 'Display Manifest',   description: 'Enable display of the installation manifest.', type: 'boolean' },
    },
  },
}

const section = computed(() => route.query.config || 'general')
const meta = computed(() => SECTION_META[section.value] || SECTION_META.general)

async function load() {
  loading.value = true
  const { data } = await client.get('/app_config', { params: { config: section.value } })
  const fields = meta.value.fields
  const init = {}
  Object.keys(fields).forEach(k => { init[k] = data.configs[k] ?? '' })
  form.value = init
  showSecret.value = {}
  loading.value = false
}

watch(section, load, { immediate: true })

async function save() {
  await client.put(`/app_config?config=${section.value}`, form.value)
  saved.value = true
  setTimeout(() => saved.value = false, 3000)
}

function toggleSecret(key) {
  showSecret.value[key] = !showSecret.value[key]
}
</script>

<template>
  <div class="max-w-2xl">
    <!-- Page header -->
    <header class="flex items-center border-b border-slate-100 pb-4 mb-6">
      <div class="border border-slate-200 mr-4 p-2 rounded-full text-slate-600">
        <i :class="meta.icon" class="text-xl leading-none"></i>
      </div>
      <div>
        <h1 class="text-base font-medium text-slate-800">{{ meta.label }}</h1>
        <p class="text-sm text-slate-500 mt-0.5">{{ meta.description }}</p>
      </div>
    </header>

    <div v-if="saved" class="mb-4 p-3 bg-green-50 border border-green-200 text-green-700 rounded text-sm">
      Settings saved successfully.
    </div>

    <form v-if="!loading" @submit.prevent="save" class="bg-white rounded-lg shadow divide-y divide-slate-100">
      <div v-for="(fieldMeta, key) in meta.fields" :key="key" class="flex px-6 py-5 gap-6">
        <!-- Label column -->
        <div class="w-48 shrink-0">
          <label :for="key" class="block text-sm font-medium text-slate-800">{{ fieldMeta.label }}</label>
          <p class="mt-1 text-xs text-slate-400 leading-relaxed">{{ fieldMeta.description }}</p>
        </div>

        <!-- Field column -->
        <div class="flex-1">
          <!-- Boolean -->
          <select
            v-if="fieldMeta.type === 'boolean'"
            :id="key" v-model="form[key]"
            class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
          >
            <option value="true">True</option>
            <option value="false">False</option>
          </select>

          <!-- Secret -->
          <div v-else-if="fieldMeta.type === 'secret'" class="relative">
            <input
              :id="key" v-model="form[key]"
              :type="showSecret[key] ? 'text' : 'password'"
              class="w-full border border-slate-200 rounded px-3 py-2 pr-9 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
            />
            <button
              type="button"
              @click="toggleSecret(key)"
              class="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
            >
              <i :class="showSecret[key] ? 'ri-eye-off-line' : 'ri-eye-line'" class="text-base"></i>
            </button>
          </div>

          <!-- Text (default) -->
          <input
            v-else
            :id="key" v-model="form[key]"
            type="text"
            class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
          />
        </div>
      </div>

      <div class="px-6 py-4 flex justify-end">
        <button type="submit" class="bg-woot-500 text-white px-5 py-2 rounded text-sm hover:bg-woot-600">
          Save Settings
        </button>
      </div>
    </form>

    <div v-else class="text-slate-400 text-sm py-8 text-center">Loading...</div>
  </div>
</template>
