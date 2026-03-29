<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import client from '../../api/client'

const route = useRoute()
const router = useRouter()
const isEdit = computed(() => !!route.params.id)
const error = ref('')
const form = ref({ name: '', display_name: '', email: '', password: '', type: 'User' })

onMounted(async () => {
  if (isEdit.value) {
    const { data } = await client.get(`/users/${route.params.id}`)
    const u = data.user
    form.value = { name: u.name, display_name: u.display_name, email: u.email, password: '', type: u.type }
  }
})

async function submit() {
  error.value = ''
  try {
    const payload = { ...form.value }
    if (!payload.password) delete payload.password
    if (isEdit.value) {
      await client.put(`/users/${route.params.id}`, payload)
      router.push(`/super_admin/users/${route.params.id}`)
    } else {
      const { data } = await client.post('/users', payload)
      router.push(`/super_admin/users/${data.id}`)
    }
  } catch (e) {
    error.value = e.response?.data?.error || 'An error occurred'
  }
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
