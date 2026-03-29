<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import client from '../../api/client'

const route = useRoute()
const router = useRouter()
const account = ref(null)
const accountUsers = ref([])
const addForm = ref({ user_id: null, role: 0 })
const addError = ref('')
const addSuccess = ref(false)

// User autocomplete
const userQuery = ref('')
const userSuggestions = ref([])
const selectedUser = ref(null)
const showUserSuggestions = ref(false)
let userSearchTimer = null

async function onUserInput() {
  selectedUser.value = null
  addForm.value.user_id = null
  clearTimeout(userSearchTimer)
  if (!userQuery.value.trim()) {
    userSuggestions.value = []
    showUserSuggestions.value = false
    return
  }
  userSearchTimer = setTimeout(async () => {
    const { data } = await client.get('/users', { params: { search: userQuery.value, page: 1 } })
    userSuggestions.value = data.data || []
    showUserSuggestions.value = true
  }, 250)
}

function selectUser(u) {
  selectedUser.value = u
  addForm.value.user_id = u.id
  userQuery.value = `${u.name} (${u.email})`
  showUserSuggestions.value = false
}

function onUserBlur() {
  setTimeout(() => { showUserSuggestions.value = false }, 150)
}

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

onMounted(async () => {
  const { data } = await client.get(`/accounts/${route.params.id}`)
  account.value = data.account
  accountUsers.value = data.account_users || []
})

async function deleteAccount() {
  if (!confirm('Delete this account?')) return
  await client.delete(`/accounts/${route.params.id}`)
  router.push('/super_admin/accounts')
}

async function seed() {
  await client.post(`/accounts/${route.params.id}/seed`)
  alert('Seed job enqueued')
}

async function resetCache() {
  await client.post(`/accounts/${route.params.id}/reset_cache`)
  alert('Cache reset')
}

async function removeAccountUser(id) {
  if (!confirm('Remove user from account?')) return
  await client.delete(`/account_users/${id}`)
  accountUsers.value = accountUsers.value.filter(au => au.id !== id)
}

async function addToAccount() {
  addError.value = ''
  if (!addForm.value.user_id) {
    addError.value = 'Please select a user'
    return
  }
  try {
    const { data } = await client.post('/account_users', {
      account_id: account.value.id,
      user_id: addForm.value.user_id,
      role: parseInt(addForm.value.role),
    })
    accountUsers.value.push(data)
    addForm.value = { user_id: null, role: 0 }
    userQuery.value = ''
    selectedUser.value = null
    addSuccess.value = true
    setTimeout(() => addSuccess.value = false, 3000)
  } catch (e) {
    addError.value = e.response?.data?.error || 'Error adding user'
  }
}

const featureList = computed(() => {
  if (!account.value) return []
  const flags = BigInt(account.value.feature_flags || 0)
  return FEATURES
    .map((f, i) => ({ ...f, enabled: !!(flags & (1n << BigInt(i))) }))
    .filter(f => !f.d && !f.i && !f.p)
    .sort((a, b) => a.label.localeCompare(b.label))
})

const enabledCount = computed(() => featureList.value.filter(f => f.enabled).length)

const LOCALES = {
  0: 'English (en)', 1: 'Arabic (ar)', 2: 'Catalan (ca)', 3: 'Czech (cs)',
  4: 'Danish (da)', 5: 'German (de)', 6: 'Greek (el)', 7: 'Spanish (es)',
  8: 'Persian (fa)', 9: 'Finnish (fi)', 10: 'French (fr)', 11: 'Hebrew (he)',
  12: 'Hungarian (hu)', 13: 'Indonesian (id)', 14: 'Italian (it)', 15: 'Japanese (ja)',
  16: 'Korean (ko)', 17: 'Malayalam (ml)', 18: 'Dutch (nl)', 19: 'Norwegian (no)',
  20: 'Polish (pl)', 21: 'Portuguese (pt)', 22: 'Portuguese, Brazil (pt_BR)', 23: 'Romanian (ro)',
  24: 'Russian (ru)', 25: 'Swedish (sv)', 26: 'Tamil (ta)', 27: 'Thai (th)',
  28: 'Turkish (tr)', 29: 'Ukrainian (uk)', 30: 'Vietnamese (vi)',
  31: 'Chinese Simplified (zh_CN)', 32: 'Chinese Traditional (zh_TW)',
}

function formatLocale(val) {
  return LOCALES[val] ?? `Unknown (${val})`
}

function formatDate(val) {
  if (!val) return '—'
  return new Date(val).toLocaleString()
}

function formatJson(val) {
  if (!val || Object.keys(val).length === 0) return '—'
  return JSON.stringify(val, null, 2)
}
</script>

<template>
  <div v-if="account">
    <!-- Page header -->
    <header class="flex items-center justify-between mb-6 pb-4 border-b border-slate-100">
      <div class="flex items-center gap-4">
        <div class="h-12 w-12 rounded-lg bg-woot-100 flex items-center justify-center text-woot-500 font-bold text-xl shrink-0">
          {{ account.name[0]?.toUpperCase() }}
        </div>
        <div>
          <div class="flex items-center gap-2">
            <h1 class="text-xl font-medium text-slate-800">{{ account.name }}</h1>
            <span :class="account.status === 0 ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'" class="px-2 py-0.5 rounded-full text-xs font-medium">
              {{ account.status === 0 ? 'active' : 'suspended' }}
            </span>
          </div>
          <p class="text-sm text-slate-500 mt-0.5">ID #{{ account.id }} · {{ account.user_count }} users · {{ account.inbox_count }} inboxes · {{ account.conversation_count }} conversations</p>
        </div>
      </div>
      <div class="flex gap-2">
        <RouterLink to="/super_admin/accounts" class="text-slate-500 hover:text-slate-700 text-sm px-3 py-1.5 border border-slate-200 rounded hover:bg-slate-25">
          ← Back
        </RouterLink>
        <RouterLink :to="`/super_admin/accounts/${account.id}/edit`" class="bg-woot-500 text-white px-4 py-1.5 rounded text-sm hover:bg-woot-600">Edit</RouterLink>
        <button @click="deleteAccount" class="bg-red-600 text-white px-4 py-1.5 rounded text-sm hover:bg-red-700">Delete</button>
      </div>
    </header>

    <!-- Basic info -->
    <div class="bg-white rounded-lg shadow p-6 mb-4">
      <h2 class="text-sm font-medium text-slate-700 mb-4 uppercase tracking-wide">Account Details</h2>
      <dl class="grid grid-cols-2 md:grid-cols-3 gap-x-8 gap-y-4 text-sm">
        <div>
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">ID</dt>
          <dd class="text-slate-800">{{ account.id }}</dd>
        </div>
        <div>
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Status</dt>
          <dd>
            <span :class="account.status === 0 ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'" class="px-2 py-0.5 rounded-full text-xs font-medium">
              {{ account.status === 0 ? 'Active' : 'Suspended' }}
            </span>
          </dd>
        </div>
        <div>
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Locale</dt>
          <dd class="text-slate-800 text-sm">{{ formatLocale(account.locale) }}</dd>
        </div>
        <div>
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Domain</dt>
          <dd class="text-slate-800">{{ account.domain || '—' }}</dd>
        </div>
        <div>
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Support Email</dt>
          <dd class="text-slate-800">{{ account.support_email || '—' }}</dd>
        </div>
        <div>
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Auto Resolve (hours)</dt>
          <dd class="text-slate-800">{{ account.auto_resolve_duration ?? '—' }}</dd>
        </div>
        <div>
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Agents</dt>
          <dd class="text-slate-800 font-semibold">{{ account.user_count }}</dd>
        </div>
        <div>
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Inboxes</dt>
          <dd class="text-slate-800 font-semibold">{{ account.inbox_count }}</dd>
        </div>
        <div>
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Conversations</dt>
          <dd class="text-slate-800 font-semibold">{{ account.conversation_count }}</dd>
        </div>
        <div>
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Features Enabled</dt>
          <dd class="text-slate-800 font-semibold">{{ enabledCount }} / {{ featureList.length }}</dd>
        </div>
        <div class="col-span-2 md:col-span-3">
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Created At</dt>
          <dd class="text-slate-800">{{ formatDate(account.created_at) }}</dd>
        </div>
        <div class="col-span-2 md:col-span-3">
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Updated At</dt>
          <dd class="text-slate-800">{{ formatDate(account.updated_at) }}</dd>
        </div>
      </dl>
    </div>

    <!-- Limits & Custom Attributes -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-sm font-medium text-slate-700 mb-3 uppercase tracking-wide">Limits</h2>
        <dl class="text-sm divide-y divide-slate-100">
          <div v-for="key in ['agents', 'inboxes', 'emails', 'captain_responses', 'captain_documents']" :key="key" class="flex justify-between py-2">
            <dt class="text-slate-500 capitalize">{{ key.replace(/_/g, ' ') }}</dt>
            <dd class="text-slate-800 font-medium">{{ (account.limits || {})[key] ?? '—' }}</dd>
          </div>
        </dl>
      </div>
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-sm font-medium text-slate-700 mb-3 uppercase tracking-wide">Custom Attributes</h2>
        <pre v-if="Object.keys(account.custom_attributes || {}).length" class="text-xs font-mono text-slate-600 bg-slate-25 p-3 rounded overflow-auto max-h-40">{{ formatJson(account.custom_attributes) }}</pre>
        <p v-else class="text-slate-400 text-sm">No custom attributes</p>
      </div>
    </div>

    <!-- Features -->
    <div class="bg-white rounded-lg shadow p-6 mb-4">
      <h2 class="text-sm font-medium text-slate-700 mb-4 uppercase tracking-wide">Features</h2>
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2">
        <div
          v-for="f in featureList"
          :key="f.name"
          class="flex items-center gap-2 px-3 py-2 rounded-lg border text-sm"
          :class="f.enabled ? 'border-green-200 bg-green-50' : 'border-slate-100 bg-slate-25'"
        >
          <i :class="f.enabled ? 'ri-check-line text-green-500' : 'ri-close-line text-slate-300'" class="text-base shrink-0"></i>
          <span :class="f.enabled ? 'text-slate-800' : 'text-slate-400'" class="text-xs truncate">{{ f.label }}</span>
        </div>
      </div>
    </div>

    <!-- Account Users -->
    <div class="bg-white rounded-lg shadow p-6 mb-4">
      <h2 class="text-sm font-medium text-slate-700 mb-4 uppercase tracking-wide">Users ({{ accountUsers.length }})</h2>
      <table v-if="accountUsers.length" class="w-full text-sm mb-4">
        <thead>
          <tr class="text-left text-slate-500 text-xs uppercase border-b border-slate-100">
            <th class="pb-2 font-medium">Name</th>
            <th class="pb-2 font-medium">Email</th>
            <th class="pb-2 font-medium">Role</th>
            <th class="pb-2"></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="au in accountUsers" :key="au.id" class="border-b border-slate-100 last:border-0">
            <td class="py-2.5 font-medium text-slate-800">{{ au.user?.name || '—' }}</td>
            <td class="py-2.5 text-slate-500 text-xs">{{ au.user?.email || '—' }}</td>
            <td class="py-2.5">
              <span :class="au.role === 1 ? 'bg-blue-100 text-blue-700' : 'bg-slate-100 text-slate-600'" class="px-2 py-0.5 rounded-full text-xs font-medium">
                {{ au.role === 1 ? 'Administrator' : 'Agent' }}
              </span>
            </td>
            <td class="py-2.5 text-right">
              <RouterLink :to="`/super_admin/users/${au.user_id}`" class="text-woot-500 hover:underline text-xs mr-3">View</RouterLink>
              <button @click="removeAccountUser(au.id)" class="text-red-500 hover:underline text-xs">Remove</button>
            </td>
          </tr>
        </tbody>
      </table>
      <p v-else class="text-slate-400 text-sm mb-4">No users in this account.</p>

      <!-- Add user form -->
      <div class="border-t border-slate-100 pt-4">
        <h3 class="text-sm font-medium text-slate-700 mb-3">Add User to Account</h3>
        <div v-if="addSuccess" class="mb-3 p-2 bg-green-50 border border-green-200 text-green-700 rounded text-xs">User added successfully</div>
        <div v-if="addError" class="mb-3 p-2 bg-red-50 border border-red-200 text-red-700 rounded text-xs">{{ addError }}</div>
        <form @submit.prevent="addToAccount" class="flex items-end gap-3">
          <div class="flex-1 relative">
            <label class="block text-xs text-slate-500 mb-1">User</label>
            <input
              v-model="userQuery"
              @input="onUserInput"
              @focus="userQuery && !selectedUser && onUserInput()"
              @blur="onUserBlur"
              placeholder="Type to search users..."
              autocomplete="off"
              class="w-full border rounded px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
              :class="selectedUser ? 'border-woot-500 bg-woot-25' : 'border-slate-200'"
            />
            <!-- Dropdown -->
            <ul v-if="showUserSuggestions && userSuggestions.length" class="absolute z-10 mt-1 w-full bg-white border border-slate-200 rounded shadow-lg max-h-48 overflow-y-auto">
              <li
                v-for="u in userSuggestions"
                :key="u.id"
                @mousedown.prevent="selectUser(u)"
                class="flex items-center justify-between px-3 py-2 text-sm cursor-pointer hover:bg-slate-25"
              >
                <div>
                  <span class="font-medium text-slate-800">{{ u.name }}</span>
                  <span class="ml-2 text-xs text-slate-400">{{ u.email }}</span>
                </div>
                <span class="text-xs text-slate-400">#{{ u.id }}</span>
              </li>
            </ul>
            <p v-if="showUserSuggestions && userSuggestions.length === 0" class="absolute z-10 mt-1 w-full bg-white border border-slate-200 rounded shadow-lg px-3 py-2 text-sm text-slate-400">
              No users found
            </p>
          </div>
          <div class="flex-1">
            <label class="block text-xs text-slate-500 mb-1">Role</label>
            <select v-model="addForm.role" class="w-full border border-slate-200 rounded px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500">
              <option :value="0">Agent</option>
              <option :value="1">Administrator</option>
            </select>
          </div>
          <button type="submit" class="bg-woot-500 text-white px-4 py-1.5 rounded text-sm hover:bg-woot-600 shrink-0">Add</button>
        </form>
      </div>
    </div>

    <!-- Actions -->
    <div class="bg-white rounded-lg shadow p-6">
      <h2 class="text-sm font-medium text-slate-700 mb-4 uppercase tracking-wide">Actions</h2>
      <div class="flex gap-3 flex-wrap">
        <button @click="seed" class="flex items-center gap-1.5 bg-green-600 text-white px-4 py-2 rounded text-sm hover:bg-green-700">
          <i class="ri-database-2-line"></i> Seed Data
        </button>
        <button @click="resetCache" class="flex items-center gap-1.5 bg-yellow-500 text-white px-4 py-2 rounded text-sm hover:bg-yellow-600">
          <i class="ri-refresh-line"></i> Reset Cache
        </button>
      </div>
    </div>
  </div>
</template>
