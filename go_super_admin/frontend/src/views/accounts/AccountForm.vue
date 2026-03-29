<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import client from '../../api/client'

const route = useRoute()
const router = useRouter()
const isEdit = computed(() => !!route.params.id)
const error = ref('')
const form = ref({
  name: '',
  status: 0,
  locale: 0,
  domain: '',
  support_email: '',
  auto_resolve_duration: '',
})
const limits = ref({ agents: '', inboxes: '', emails: '', captain_responses: '', captain_documents: '' })
const LIMIT_FIELDS = [
  { key: 'agents',             label: 'Agents',             description: 'Maximum number of agents allowed.' },
  { key: 'inboxes',            label: 'Inboxes',            description: 'Maximum number of inboxes allowed.' },
  { key: 'emails',             label: 'Emails',             description: 'Email rate limit.' },
  { key: 'captain_responses',  label: 'Captain Responses',  description: 'Captain AI response limit.' },
  { key: 'captain_documents',  label: 'Captain Documents',  description: 'Captain AI document limit.' },
]
// Feature flags bitmask — DO NOT reorder; must match config/features.yml exactly
// d=deprecated, i=internal (chatwoot_internal), p=premium
const FEATURES = [
  { key: 'inbound_emails',                   label: 'Inbound Emails' },
  { key: 'channel_email',                    label: 'Email Channel' },
  { key: 'channel_facebook',                 label: 'Facebook Channel' },
  { key: 'channel_twitter',                  label: 'Twitter Channel',                  d: true },
  { key: 'ip_lookup',                        label: 'IP Lookup' },
  { key: 'disable_branding',                 label: 'Disable Branding',                 p: true },
  { key: 'email_continuity_on_api_channel',  label: 'Email Continuity on API Channel' },
  { key: 'help_center',                      label: 'Help Center' },
  { key: 'agent_bots',                       label: 'Agent Bots' },
  { key: 'macros',                           label: 'Macros' },
  { key: 'agent_management',                 label: 'Agent Management' },
  { key: 'team_management',                  label: 'Team Management' },
  { key: 'inbox_management',                 label: 'Inbox Management' },
  { key: 'labels',                           label: 'Labels' },
  { key: 'custom_attributes',                label: 'Custom Attributes' },
  { key: 'automations',                      label: 'Automations' },
  { key: 'canned_responses',                 label: 'Canned Responses' },
  { key: 'integrations',                     label: 'Integrations' },
  { key: 'voice_recorder',                   label: 'Voice Recorder' },
  { key: 'report_rollup',                    label: 'Report Rollup' },
  { key: 'channel_website',                  label: 'Website Channel' },
  { key: 'campaigns',                        label: 'Campaigns' },
  { key: 'reports',                          label: 'Reports' },
  { key: 'crm',                              label: 'CRM' },
  { key: 'auto_resolve_conversations',       label: 'Auto Resolve Conversations' },
  { key: 'custom_reply_email',               label: 'Custom Reply Email' },
  { key: 'custom_reply_domain',              label: 'Custom Reply Domain' },
  { key: 'audit_logs',                       label: 'Audit Logs',                       p: true },
  { key: 'response_bot',                     label: 'Response Bot',                     d: true },
  { key: 'message_reply_to',                 label: 'Message Reply To',                 d: true },
  { key: 'insert_article_in_reply',          label: 'Insert Article in Reply',          d: true },
  { key: 'inbox_view',                       label: 'Inbox View',                       i: true },
  { key: 'sla',                              label: 'SLA',                              p: true },
  { key: 'help_center_embedding_search',     label: 'Help Center Embedding Search',     p: true, i: true },
  { key: 'custom_roles',                     label: 'Custom Roles',                     p: true },
  { key: 'chatwoot_v4',                      label: 'Chatwoot V4' },
  { key: 'report_v4',                        label: 'Report V4',                        d: true },
  { key: 'contact_chatwoot_support_team',    label: 'Contact Chatwoot Support Team',    i: true },
  { key: 'shopify_integration',              label: 'Shopify Integration',              i: true },
  { key: 'search_with_gin',                  label: 'Search with GIN',                  i: true },
  { key: 'channel_instagram',                label: 'Instagram Channel' },
  { key: 'crm_integration',                  label: 'CRM Integration' },
  { key: 'channel_voice',                    label: 'Voice Channel',                    p: true },
  { key: 'notion_integration',               label: 'Notion Integration' },
  { key: 'whatsapp_embedded_signup',         label: 'WhatsApp Embedded Signup',         d: true },
  { key: 'whatsapp_campaign',                label: 'WhatsApp Campaign' },
  { key: 'crm_v2',                           label: 'CRM V2',                           i: true },
  { key: 'assignment_v2',                    label: 'Assignment V2' },
  { key: 'twilio_content_templates',         label: 'Twilio Content Templates',         d: true },
  { key: 'advanced_search',                  label: 'Advanced Search',                  p: true, i: true },
  { key: 'saml',                             label: 'SAML',                             p: true },
  { key: 'advanced_search_indexing',         label: 'Advanced Search Indexing',         p: true, i: true },
  { key: 'reply_mailer_migration',           label: 'Reply Mailer Migration',           i: true },
  { key: 'quoted_email_reply',               label: 'Quoted Email Reply' },
  { key: 'companies',                        label: 'Companies',                        p: true, i: true },
  { key: 'channel_tiktok',                   label: 'TikTok Channel' },
  { key: 'csat_review_notes',                label: 'CSAT Review Notes',                p: true },
  { key: 'conversation_required_attributes', label: 'Required Conversation Attributes', p: true },
  { key: 'advanced_assignment',              label: 'Advanced Assignment',              p: true },
]
const displayFeatures = computed(() =>
  FEATURES
    .filter(f => !f.d && !f.i && !f.p)
    .sort((a, b) => a.label.localeCompare(b.label))
)
const featureEnabled = ref({})

function initFeatures(flags) {
  const enabled = {}
  const bigFlags = BigInt(flags)
  FEATURES.forEach((f, i) => { enabled[f.key] = !!(bigFlags & (1n << BigInt(i))) })
  featureEnabled.value = enabled
}

function buildFeatureFlags() {
  let flags = 0n
  FEATURES.forEach((f, i) => { if (featureEnabled.value[f.key]) flags |= (1n << BigInt(i)) })
  return Number(flags)
}

// Same locale list as LANGUAGES_CONFIG in Ruby
const LOCALES = [
  { value: 0,  label: 'English (en)' },
  { value: 1,  label: 'Arabic (ar)' },
  { value: 2,  label: 'Catalan (ca)' },
  { value: 3,  label: 'Czech (cs)' },
  { value: 4,  label: 'Danish (da)' },
  { value: 5,  label: 'German (de)' },
  { value: 6,  label: 'Greek (el)' },
  { value: 7,  label: 'Spanish (es)' },
  { value: 8,  label: 'Persian (fa)' },
  { value: 9,  label: 'Finnish (fi)' },
  { value: 10, label: 'French (fr)' },
  { value: 11, label: 'Hebrew (he)' },
  { value: 12, label: 'Hungarian (hu)' },
  { value: 13, label: 'Indonesian (id)' },
  { value: 14, label: 'Italian (it)' },
  { value: 15, label: 'Japanese (ja)' },
  { value: 16, label: 'Korean (ko)' },
  { value: 17, label: 'Malayalam (ml)' },
  { value: 18, label: 'Dutch (nl)' },
  { value: 19, label: 'Norwegian (no)' },
  { value: 20, label: 'Polish (pl)' },
  { value: 21, label: 'Portuguese (pt)' },
  { value: 22, label: 'Portuguese, Brazil (pt_BR)' },
  { value: 23, label: 'Romanian (ro)' },
  { value: 24, label: 'Russian (ru)' },
  { value: 25, label: 'Swedish (sv)' },
  { value: 26, label: 'Tamil (ta)' },
  { value: 27, label: 'Thai (th)' },
  { value: 28, label: 'Turkish (tr)' },
  { value: 29, label: 'Ukrainian (uk)' },
  { value: 30, label: 'Vietnamese (vi)' },
  { value: 31, label: 'Chinese Simplified (zh_CN)' },
  { value: 32, label: 'Chinese Traditional (zh_TW)' },
]

onMounted(async () => {
  if (isEdit.value) {
    const { data } = await client.get(`/accounts/${route.params.id}`)
    const a = data.account ?? data
    form.value = {
      name: a.name,
      status: a.status,
      locale: a.locale,
      domain: a.domain || '',
      support_email: a.support_email || '',
      auto_resolve_duration: a.auto_resolve_duration ?? '',
    }
    const l = a.limits || {}
    limits.value = {
      agents:             l.agents             != null ? String(l.agents)             : '',
      inboxes:            l.inboxes            != null ? String(l.inboxes)            : '',
      emails:             l.emails             != null ? String(l.emails)             : '',
      captain_responses:  l.captain_responses  != null ? String(l.captain_responses)  : '',
      captain_documents:  l.captain_documents  != null ? String(l.captain_documents)  : '',
    }
    initFeatures(a.feature_flags || 0)
  } else {
    initFeatures(0)
  }
})

async function submit() {
  error.value = ''
  try {
    const builtLimits = {}
    for (const [k, v] of Object.entries(limits.value)) {
      if (v !== '') builtLimits[k] = parseInt(v)
    }
    const payload = {
      ...form.value,
      auto_resolve_duration: form.value.auto_resolve_duration !== ''
        ? parseInt(form.value.auto_resolve_duration)
        : null,
      feature_flags: buildFeatureFlags(),
      limits: builtLimits,
    }
    if (isEdit.value) {
      await client.put(`/accounts/${route.params.id}`, payload)
      router.push(`/super_admin/accounts/${route.params.id}`)
    } else {
      const { data } = await client.post('/accounts', payload)
      router.push(`/super_admin/accounts/${data.id}`)
    }
  } catch (e) {
    error.value = e.response?.data?.error || 'An error occurred'
  }
}
</script>

<template>
  <div class="max-w-2xl">
    <!-- Header -->
    <header class="flex items-center justify-between mb-6 pb-4 border-b border-slate-100">
      <div>
        <RouterLink to="/super_admin/accounts" class="text-slate-500 hover:text-slate-700 text-sm">← Accounts</RouterLink>
        <h1 class="text-xl font-medium text-slate-800 mt-1">{{ isEdit ? 'Edit Account' : 'New Account' }}</h1>
      </div>
    </header>

    <div v-if="error" class="mb-4 rounded-md bg-red-500 p-4 text-white text-sm">{{ error }}</div>

    <form @submit.prevent="submit" class="bg-white rounded-lg shadow divide-y divide-slate-100">
      <!-- Name -->
      <div class="flex px-6 py-5 gap-6">
        <div class="w-48 shrink-0">
          <label for="name" class="block text-sm font-medium text-slate-800">Name <span class="text-red-500">*</span></label>
          <p class="mt-1 text-xs text-slate-400">The display name of the account.</p>
        </div>
        <div class="flex-1">
          <input
            id="name" v-model="form.name" required
            class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
            placeholder="e.g. Acme Corp"
          />
        </div>
      </div>

      <!-- Status -->
      <div class="flex px-6 py-5 gap-6">
        <div class="w-48 shrink-0">
          <label for="status" class="block text-sm font-medium text-slate-800">Status</label>
          <p class="mt-1 text-xs text-slate-400">Active accounts can log in and use Chatwoot.</p>
        </div>
        <div class="flex-1">
          <select
            id="status" v-model="form.status"
            class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
          >
            <option :value="0">Active</option>
            <option :value="1">Suspended</option>
          </select>
        </div>
      </div>

      <!-- Locale -->
      <div class="flex px-6 py-5 gap-6">
        <div class="w-48 shrink-0">
          <label for="locale" class="block text-sm font-medium text-slate-800">Locale</label>
          <p class="mt-1 text-xs text-slate-400">Default language for this account.</p>
        </div>
        <div class="flex-1">
          <select
            id="locale" v-model="form.locale"
            class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
          >
            <option v-for="loc in LOCALES" :key="loc.value" :value="loc.value">{{ loc.label }}</option>
          </select>
        </div>
      </div>

      <!-- Domain -->
      <div class="flex px-6 py-5 gap-6">
        <div class="w-48 shrink-0">
          <label for="domain" class="block text-sm font-medium text-slate-800">Domain</label>
          <p class="mt-1 text-xs text-slate-400">Custom domain for this account's help center.</p>
        </div>
        <div class="flex-1">
          <input
            id="domain" v-model="form.domain"
            type="text"
            class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
            placeholder="e.g. support.acme.com"
          />
        </div>
      </div>

      <!-- Support Email -->
      <div class="flex px-6 py-5 gap-6">
        <div class="w-48 shrink-0">
          <label for="support_email" class="block text-sm font-medium text-slate-800">Support Email</label>
          <p class="mt-1 text-xs text-slate-400">Default reply-to email for outgoing messages.</p>
        </div>
        <div class="flex-1">
          <input
            id="support_email" v-model="form.support_email"
            type="email"
            class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
            placeholder="e.g. support@acme.com"
          />
        </div>
      </div>

      <!-- Auto Resolve Duration -->
      <div class="flex px-6 py-5 gap-6">
        <div class="w-48 shrink-0">
          <label for="auto_resolve_duration" class="block text-sm font-medium text-slate-800">Auto Resolve Duration</label>
          <p class="mt-1 text-xs text-slate-400">Hours after which inactive conversations are auto-resolved. Leave blank to disable.</p>
        </div>
        <div class="flex-1">
          <input
            id="auto_resolve_duration" v-model="form.auto_resolve_duration"
            type="number" min="0"
            class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
            placeholder="e.g. 24"
          />
        </div>
      </div>

      <!-- Limits -->
      <div class="flex px-6 py-5 gap-6">
        <div class="w-48 shrink-0">
          <label class="block text-sm font-medium text-slate-800">Limits</label>
          <p class="mt-1 text-xs text-slate-400">Leave blank to use the global default (no limit).</p>
        </div>
        <div class="flex-1 grid grid-cols-2 gap-x-4 gap-y-3">
          <div v-for="f in LIMIT_FIELDS" :key="f.key">
            <label :for="`limit_${f.key}`" class="block text-xs font-medium text-slate-600 mb-1">{{ f.label }}</label>
            <input
              :id="`limit_${f.key}`" v-model="limits[f.key]"
              type="number" min="0"
              :placeholder="f.description"
              class="w-full border border-slate-200 rounded px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
            />
          </div>
        </div>
      </div>

      <!-- Features -->
      <div class="flex px-6 py-5 gap-6">
        <div class="w-48 shrink-0">
          <label class="block text-sm font-medium text-slate-800">Features</label>
          <p class="mt-1 text-xs text-slate-400">Toggle features for this account.</p>
        </div>
        <div class="flex-1 grid grid-cols-2 gap-x-4 gap-y-2">
          <label
            v-for="f in displayFeatures"
            :key="f.key"
            class="flex items-center gap-2 cursor-pointer select-none"
          >
            <input
              type="checkbox"
              v-model="featureEnabled[f.key]"
              class="w-4 h-4 rounded border-slate-300 text-woot-500 focus:ring-woot-500 cursor-pointer"
            />
            <span class="text-sm text-slate-700">{{ f.label }}</span>
          </label>
        </div>
      </div>

      <!-- Submit -->
      <div class="px-6 py-4 flex justify-end gap-3">
        <RouterLink
          :to="isEdit ? `/super_admin/accounts/${route.params.id}` : '/super_admin/accounts'"
          class="px-4 py-2 border border-slate-200 rounded text-sm text-slate-600 hover:bg-slate-25"
        >
          Cancel
        </RouterLink>
        <button type="submit" class="bg-woot-500 text-white px-5 py-2 rounded text-sm hover:bg-woot-600">
          {{ isEdit ? 'Update Account' : 'Create Account' }}
        </button>
      </div>
    </form>
  </div>
</template>
