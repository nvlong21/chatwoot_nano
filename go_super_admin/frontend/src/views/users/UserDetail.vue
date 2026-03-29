<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import client from '../../api/client'

const route = useRoute()
const router = useRouter()
const user = ref(null)
const accountUsers = ref([])
const addForm = ref({ account_id: null, role: 0 })
const addError = ref('')
const addSuccess = ref(false)

// Account autocomplete
const accountQuery = ref('')
const accountSuggestions = ref([])
const selectedAccount = ref(null)
const showSuggestions = ref(false)
let searchTimer = null

async function onAccountInput() {
  selectedAccount.value = null
  addForm.value.account_id = null
  clearTimeout(searchTimer)
  if (!accountQuery.value.trim()) {
    accountSuggestions.value = []
    showSuggestions.value = false
    return
  }
  searchTimer = setTimeout(async () => {
    const { data } = await client.get('/accounts', { params: { search: accountQuery.value, page: 1 } })
    accountSuggestions.value = data.data || []
    showSuggestions.value = true
  }, 250)
}

function selectAccount(account) {
  selectedAccount.value = account
  addForm.value.account_id = account.id
  accountQuery.value = `${account.name} (#${account.id})`
  showSuggestions.value = false
}

function onAccountBlur() {
  setTimeout(() => { showSuggestions.value = false }, 150)
}

onMounted(async () => {
  const { data } = await client.get(`/users/${route.params.id}`)
  user.value = data.user
  accountUsers.value = data.account_users || []
})

async function deleteUser() {
  if (!confirm('Delete this user?')) return
  await client.delete(`/users/${route.params.id}`)
  router.push('/super_admin/users')
}

async function removeAccountUser(id) {
  if (!confirm('Remove from account?')) return
  await client.delete(`/account_users/${id}`)
  accountUsers.value = accountUsers.value.filter(au => au.id !== id)
}

async function addToAccount() {
  addError.value = ''
  if (!addForm.value.account_id) {
    addError.value = 'Please select an account'
    return
  }
  try {
    const { data } = await client.post('/account_users', {
      user_id: user.value.id,
      account_id: addForm.value.account_id,
      role: parseInt(addForm.value.role),
    })
    accountUsers.value.push(data)
    addForm.value = { account_id: null, role: 0 }
    accountQuery.value = ''
    selectedAccount.value = null
    addSuccess.value = true
    setTimeout(() => addSuccess.value = false, 3000)
  } catch (e) {
    addError.value = e.response?.data?.error || 'Error adding to account'
  }
}

const initials = computed(() => {
  if (!user.value?.name) return '?'
  return user.value.name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
})

const avatarSrc = computed(() => user.value?.avatar_url || null)

function onAvatarError(e) {
  e.target.style.display = 'none'
  e.target.nextElementSibling?.classList.remove('hidden')
}

function formatDate(val) {
  if (!val) return '—'
  return new Date(val).toLocaleString()
}
</script>

<template>
  <div v-if="user">
    <!-- Page header -->
    <header class="flex items-center justify-between mb-6 pb-4 border-b border-slate-100">
      <div class="flex items-center gap-4">
        <div class="h-12 w-12 rounded-full shrink-0 relative overflow-hidden bg-woot-100 flex items-center justify-center">
          <img v-if="avatarSrc" :src="avatarSrc" @error="onAvatarError" class="absolute inset-0 w-full h-full object-cover rounded-full" />
          <span class="text-woot-500 font-semibold text-lg">{{ initials }}</span>
        </div>
        <div>
          <div class="flex items-center gap-2">
            <h1 class="text-xl font-medium text-slate-800">{{ user.name }}</h1>
            <span :class="user.type === 'SuperAdmin' ? 'bg-purple-100 text-purple-700' : 'bg-slate-100 text-slate-600'" class="px-2 py-0.5 rounded-full text-xs font-medium">
              {{ user.type }}
            </span>
          </div>
          <p class="text-sm text-slate-500 mt-0.5">{{ user.email }}</p>
        </div>
      </div>
      <div class="flex gap-2">
        <RouterLink to="/super_admin/users" class="text-slate-500 hover:text-slate-700 text-sm px-3 py-1.5 border border-slate-200 rounded hover:bg-slate-25">
          ← Back
        </RouterLink>
        <RouterLink :to="`/super_admin/users/${user.id}/edit`" class="bg-woot-500 text-white px-4 py-1.5 rounded text-sm hover:bg-woot-600">Edit</RouterLink>
        <button @click="deleteUser" class="bg-red-600 text-white px-4 py-1.5 rounded text-sm hover:bg-red-700">Delete</button>
      </div>
    </header>

    <!-- Attributes -->
    <div class="bg-white rounded-lg shadow p-6 mb-4">
      <dl class="grid grid-cols-2 gap-x-8 gap-y-4 text-sm">
        <div class="border-b border-slate-50 pb-3">
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">ID</dt>
          <dd class="text-slate-800">{{ user.id }}</dd>
        </div>
        <div class="border-b border-slate-50 pb-3">
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Display Name</dt>
          <dd class="text-slate-800">{{ user.display_name || '—' }}</dd>
        </div>
        <div class="border-b border-slate-50 pb-3">
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Email</dt>
          <dd class="text-slate-800">{{ user.email }}</dd>
        </div>
        <div class="border-b border-slate-50 pb-3">
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Type</dt>
          <dd>
            <span :class="user.type === 'SuperAdmin' ? 'bg-purple-100 text-purple-700' : 'bg-slate-100 text-slate-600'" class="px-2 py-0.5 rounded-full text-xs font-medium">
              {{ user.type }}
            </span>
          </dd>
        </div>
        <div class="border-b border-slate-50 pb-3">
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Email Confirmed</dt>
          <dd>
            <span :class="user.confirmed_at ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-600'" class="px-2 py-0.5 rounded-full text-xs font-medium">
              {{ user.confirmed_at ? 'Confirmed' : 'Unconfirmed' }}
            </span>
          </dd>
        </div>
        <div class="border-b border-slate-50 pb-3">
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Accounts Count</dt>
          <dd class="text-slate-800">{{ accountUsers.length }}</dd>
        </div>
        <div class="border-b border-slate-50 pb-3">
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Created At</dt>
          <dd class="text-slate-800">{{ formatDate(user.created_at) }}</dd>
        </div>
        <div class="border-b border-slate-50 pb-3">
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Updated At</dt>
          <dd class="text-slate-800">{{ formatDate(user.updated_at) }}</dd>
        </div>
      </dl>
    </div>

    <!-- Account associations -->
    <div class="bg-white rounded-lg shadow p-6 mb-4">
      <h2 class="text-base font-medium text-slate-800 mb-4">Account Memberships</h2>
      <table v-if="accountUsers.length" class="w-full text-sm mb-4">
        <thead>
          <tr class="text-left text-slate-500 text-xs uppercase border-b border-slate-100">
            <th class="pb-2 font-medium">Account</th>
            <th class="pb-2 font-medium">Account ID</th>
            <th class="pb-2 font-medium">Role</th>
            <th class="pb-2"></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="au in accountUsers" :key="au.id" class="border-b border-slate-100 last:border-0">
            <td class="py-2.5 font-medium text-slate-800">{{ au.account?.name || '—' }}</td>
            <td class="py-2.5 text-slate-500">#{{ au.account_id }}</td>
            <td class="py-2.5">
              <span :class="au.role === 1 ? 'bg-blue-100 text-blue-700' : 'bg-slate-100 text-slate-600'" class="px-2 py-0.5 rounded-full text-xs font-medium capitalize">
                {{ au.role === 1 ? 'Administrator' : 'Agent' }}
              </span>
            </td>
            <td class="py-2.5 text-right">
              <button @click="removeAccountUser(au.id)" class="text-red-500 hover:underline text-xs">Remove</button>
            </td>
          </tr>
        </tbody>
      </table>
      <p v-else class="text-slate-400 text-sm mb-4">Not a member of any account.</p>

      <!-- Add to account form -->
      <div class="border-t border-slate-100 pt-4">
        <h3 class="text-sm font-medium text-slate-700 mb-3">Add to Account</h3>
        <div v-if="addSuccess" class="mb-3 p-2 bg-green-50 border border-green-200 text-green-700 rounded text-xs">Added successfully</div>
        <div v-if="addError" class="mb-3 p-2 bg-red-50 border border-red-200 text-red-700 rounded text-xs">{{ addError }}</div>
        <form @submit.prevent="addToAccount" class="flex items-end gap-3">
          <div class="flex-1 relative">
            <label class="block text-xs text-slate-500 mb-1">Account</label>
            <input
              v-model="accountQuery"
              @input="onAccountInput"
              @focus="accountQuery && !selectedAccount && onAccountInput()"
              @blur="onAccountBlur"
              placeholder="Type to search accounts..."
              autocomplete="off"
              class="w-full border rounded px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500"
              :class="selectedAccount ? 'border-woot-500 bg-woot-25' : 'border-slate-200'"
            />
            <!-- Dropdown -->
            <ul v-if="showSuggestions && accountSuggestions.length" class="absolute z-10 mt-1 w-full bg-white border border-slate-200 rounded shadow-lg max-h-48 overflow-y-auto">
              <li
                v-for="acc in accountSuggestions"
                :key="acc.id"
                @mousedown.prevent="selectAccount(acc)"
                class="flex items-center justify-between px-3 py-2 text-sm cursor-pointer hover:bg-slate-25"
              >
                <span class="font-medium text-slate-800">{{ acc.name }}</span>
                <span class="text-xs text-slate-400">#{{ acc.id }}</span>
              </li>
            </ul>
            <p v-if="showSuggestions && accountSuggestions.length === 0" class="absolute z-10 mt-1 w-full bg-white border border-slate-200 rounded shadow-lg px-3 py-2 text-sm text-slate-400">
              No accounts found
            </p>
          </div>
          <div class="flex-1">
            <label class="block text-xs text-slate-500 mb-1">Role</label>
            <select v-model="addForm.role" class="w-full border border-slate-200 rounded px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500">
              <option :value="0">Agent</option>
              <option :value="1">Administrator</option>
            </select>
          </div>
          <button type="submit" class="bg-woot-500 text-white px-4 py-1.5 rounded text-sm hover:bg-woot-600 shrink-0">
            Add
          </button>
        </form>
      </div>
    </div>
  </div>
</template>
