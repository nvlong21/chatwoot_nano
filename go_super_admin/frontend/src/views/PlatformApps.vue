<script setup>
import { ref, onMounted } from 'vue'
import client from '../api/client'

const apps = ref([])
const showForm = ref(false)
const editApp = ref(null)
const form = ref({ name: '' })
const error = ref('')

async function load() {
  const { data } = await client.get('/platform_apps')
  apps.value = data.data
}

onMounted(load)

function openCreate() { editApp.value = null; form.value = { name: '' }; showForm.value = true }
function openEdit(app) { editApp.value = app; form.value = { name: app.name }; showForm.value = true }

async function submit() {
  error.value = ''
  try {
    if (editApp.value) {
      await client.put(`/platform_apps/${editApp.value.id}`, form.value)
    } else {
      await client.post('/platform_apps', form.value)
    }
    showForm.value = false
    load()
  } catch (e) {
    error.value = e.response?.data?.error || 'Error'
  }
}

async function deleteApp(id) {
  if (!confirm('Delete this platform app?')) return
  await client.delete(`/platform_apps/${id}`)
  load()
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-medium text-slate-800">Platform Apps</h1>
      <button @click="openCreate" class="bg-woot-500 text-white px-4 py-2 rounded text-sm hover:bg-woot-600">New App</button>
    </div>

    <div v-if="showForm" class="bg-white rounded-lg shadow p-6 mb-6 max-w-sm">
      <h2 class="font-semibold text-slate-800 mb-4">{{ editApp ? 'Edit App' : 'New App' }}</h2>
      <div v-if="error" class="mb-3 p-2 bg-red-50 border border-red-200 text-red-700 rounded text-sm">{{ error }}</div>
      <form @submit.prevent="submit" class="space-y-3">
        <input v-model="form.name" placeholder="Name *" required class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500" />
        <div class="flex gap-2">
          <button type="submit" class="bg-woot-500 text-white px-4 py-2 rounded text-sm hover:bg-woot-600">Save</button>
          <button type="button" @click="showForm = false" class="px-4 py-2 rounded text-sm border hover:bg-slate-25">Cancel</button>
        </div>
      </form>
    </div>

    <div class="bg-white rounded-lg shadow overflow-hidden">
      <table class="min-w-full divide-y divide-slate-100 text-sm">
        <thead class="bg-slate-25">
          <tr>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">ID</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Name</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Created</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="a in apps" :key="a.id" class="hover:bg-slate-25">
            <td class="px-4 py-3 text-slate-400 text-xs">{{ a.id }}</td>
            <td class="px-4 py-3 font-medium text-slate-800">{{ a.name }}</td>
            <td class="px-4 py-3 text-slate-500 text-xs">{{ new Date(a.created_at).toLocaleDateString() }}</td>
            <td class="px-4 py-3 flex gap-3">
              <button @click="openEdit(a)" class="text-woot-500 hover:underline">Edit</button>
              <button @click="deleteApp(a.id)" class="text-red-500 hover:underline">Delete</button>
            </td>
          </tr>
          <tr v-if="!apps.length"><td colspan="4" class="px-4 py-8 text-center text-slate-400">No apps found</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
