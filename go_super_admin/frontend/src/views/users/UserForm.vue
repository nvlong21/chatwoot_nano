<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import client from '../../api/client'

const route = useRoute()
const router = useRouter()
const isEdit = computed(() => !!route.params.id)
const error = ref('')
const form = ref({ name: '', display_name: '', email: '', password: '', type: 'User' })
const avatarUrl = ref('')
const avatarFile = ref(null)
const avatarPreview = ref('')

const initials = computed(() => {
  if (!form.value.name) return '?'
  return form.value.name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()
})

onMounted(async () => {
  if (isEdit.value) {
    const { data } = await client.get(`/users/${route.params.id}`)
    const u = data.user
    form.value = { name: u.name, display_name: u.display_name, email: u.email, password: '', type: u.type }
    avatarUrl.value = u.avatar_url || ''
  }
})

function onAvatarChange(e) {
  const file = e.target.files[0]
  if (!file) return
  avatarFile.value = file
  avatarPreview.value = URL.createObjectURL(file)
}

async function submit() {
  error.value = ''
  try {
    const payload = { ...form.value }
    if (!payload.password) delete payload.password
    let userId
    if (isEdit.value) {
      await client.put(`/users/${route.params.id}`, payload)
      userId = route.params.id
    } else {
      const { data } = await client.post('/users', payload)
      userId = data.id
    }
    if (avatarFile.value) {
      const fd = new FormData()
      fd.append('avatar', avatarFile.value)
      const { data: avatarData } = await client.post(`/users/${userId}/avatar`, fd, { headers: { 'Content-Type': 'multipart/form-data' } })
      avatarUrl.value = avatarData.avatar_url
    }
    router.push(`/super_admin/users/${userId}`)
  } catch (e) {
    error.value = e.response?.data?.error || 'An error occurred'
  }
}

function onAvatarError(e) {
  e.target.style.display = 'none'
}
</script>

<template>
  <div class="max-w-lg">
    <div class="flex items-center gap-3 mb-6">
      <RouterLink to="/super_admin/users" class="text-slate-500 hover:text-slate-700 text-sm">← Users</RouterLink>
      <h1 class="text-2xl font-medium text-slate-800">{{ isEdit ? 'Edit User' : 'New User' }}</h1>
    </div>

    <div v-if="error" class="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded text-sm">{{ error }}</div>

    <form @submit.prevent="submit" class="bg-white rounded-lg shadow p-6 space-y-4">
      <!-- Avatar -->
      <div class="flex items-center gap-4 pb-2">
        <div class="relative h-16 w-16 rounded-full bg-woot-100 flex items-center justify-center overflow-hidden shrink-0">
          <img v-if="avatarPreview || avatarUrl" :src="avatarPreview || avatarUrl" @error="onAvatarError" class="absolute inset-0 w-full h-full object-cover" />
          <span class="text-woot-500 font-semibold text-xl">{{ initials }}</span>
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Avatar</label>
          <input type="file" accept="image/jpeg,image/png,image/gif" @change="onAvatarChange" class="text-sm text-slate-500 file:mr-3 file:py-1 file:px-3 file:rounded file:border-0 file:text-xs file:bg-woot-50 file:text-woot-700 hover:file:bg-woot-100 cursor-pointer" />
        </div>
      </div>
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-1">Name *</label>
        <input v-model="form.name" required class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500" />
      </div>
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-1">Display Name</label>
        <input v-model="form.display_name" class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500" />
      </div>
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-1">Email *</label>
        <input v-model="form.email" type="email" required class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500" />
      </div>
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-1">Password {{ isEdit ? '(leave blank to keep)' : '*' }}</label>
        <input v-model="form.password" type="password" :required="!isEdit" class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500" />
      </div>
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-1">Type</label>
        <select v-model="form.type" class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500">
          <option value="User">User</option>
          <option value="SuperAdmin">SuperAdmin</option>
        </select>
      </div>
      <button type="submit" class="w-full bg-woot-500 text-white px-4 py-2 rounded text-sm hover:bg-woot-600">
        {{ isEdit ? 'Update User' : 'Create User' }}
      </button>
    </form>
  </div>
</template>
