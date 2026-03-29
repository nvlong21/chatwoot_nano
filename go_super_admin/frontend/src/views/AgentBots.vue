<script setup>
import { ref, onMounted } from 'vue'
import client from '../api/client'

const bots = ref([])
const meta = ref({})
const page = ref(1)
const showForm = ref(false)
const editBot = ref(null)
const form = ref({ name: '', description: '', outgoing_url: '', account_id: null })
const error = ref('')

async function load() {
  const { data } = await client.get('/agent_bots', { params: { page: page.value } })
  bots.value = data.data
  meta.value = data.meta
}

onMounted(load)

function openCreate() { editBot.value = null; form.value = { name: '', description: '', outgoing_url: '', account_id: null }; showForm.value = true }
function openEdit(bot) { editBot.value = bot; form.value = { name: bot.name, description: bot.description, outgoing_url: bot.outgoing_url, account_id: bot.account_id }; showForm.value = true }

async function submit() {
  error.value = ''
  try {
    if (editBot.value) {
      await client.put(`/agent_bots/${editBot.value.id}`, form.value)
    } else {
      await client.post('/agent_bots', form.value)
    }
    showForm.value = false
    load()
  } catch (e) {
    error.value = e.response?.data?.error || 'Error'
  }
}

async function deleteBot(id) {
  if (!confirm('Delete this bot?')) return
  await client.delete(`/agent_bots/${id}`)
  load()
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-medium text-slate-800">Agent Bots</h1>
      <button @click="openCreate" class="bg-woot-500 text-white px-4 py-2 rounded text-sm hover:bg-woot-600">New Bot</button>
    </div>

    <div v-if="showForm" class="bg-white rounded-lg shadow p-6 mb-6 max-w-lg">
      <h2 class="font-semibold text-slate-800 mb-4">{{ editBot ? 'Edit Bot' : 'New Bot' }}</h2>
      <div v-if="error" class="mb-3 p-2 bg-red-50 border border-red-200 text-red-700 rounded text-sm">{{ error }}</div>
      <form @submit.prevent="submit" class="space-y-3">
        <input v-model="form.name" placeholder="Name *" required class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500" />
        <input v-model="form.description" placeholder="Description" class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500" />
        <input v-model="form.outgoing_url" placeholder="Outgoing URL" class="w-full border border-slate-200 rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500" />
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
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Outgoing URL</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="b in bots" :key="b.id" class="hover:bg-slate-25">
            <td class="px-4 py-3 text-slate-400 text-xs">{{ b.id }}</td>
            <td class="px-4 py-3 font-medium text-slate-800">{{ b.name }}</td>
            <td class="px-4 py-3 text-slate-500 text-xs truncate max-w-xs">{{ b.outgoing_url || '—' }}</td>
            <td class="px-4 py-3 flex gap-3">
              <button @click="openEdit(b)" class="text-woot-500 hover:underline">Edit</button>
              <button @click="deleteBot(b.id)" class="text-red-500 hover:underline">Delete</button>
            </td>
          </tr>
          <tr v-if="!bots.length"><td colspan="4" class="px-4 py-8 text-center text-slate-400">No bots found</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
