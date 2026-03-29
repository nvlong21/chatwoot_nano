<script setup>
import { ref, onMounted } from 'vue'
import client from '../api/client'

const configs = ref([])
const editing = ref(null)
const editValue = ref('')
const error = ref('')

onMounted(async () => {
  const { data } = await client.get('/installation_configs')
  configs.value = data.data
})

function startEdit(cfg) {
  editing.value = cfg.id
  editValue.value = cfg.value || ''
}

async function saveEdit(cfg) {
  error.value = ''
  try {
    await client.put(`/installation_configs/${cfg.id}`, { value: editValue.value })
    cfg.value = editValue.value
    editing.value = null
  } catch (e) {
    error.value = e.response?.data?.error || 'Error'
  }
}
</script>

<template>
  <div>
    <h1 class="text-2xl font-medium text-slate-800 mb-6">Installation Configs</h1>
    <div v-if="error" class="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded text-sm">{{ error }}</div>

    <div class="bg-white rounded-lg shadow overflow-hidden">
      <table class="min-w-full divide-y divide-slate-100 text-sm">
        <thead class="bg-slate-25">
          <tr>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Name</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Value</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="cfg in configs" :key="cfg.id" class="hover:bg-slate-25">
            <td class="px-4 py-3 font-mono text-xs text-slate-700">{{ cfg.name }}</td>
            <td class="px-4 py-3">
              <div v-if="editing === cfg.id">
                <input v-model="editValue" class="border border-slate-200 rounded px-2 py-1 text-sm w-full focus:outline-none focus:ring-2 focus:ring-woot-500" />
              </div>
              <span v-else class="text-slate-600 text-xs">{{ cfg.value || '—' }}</span>
            </td>
            <td class="px-4 py-3 flex gap-2">
              <template v-if="editing === cfg.id">
                <button @click="saveEdit(cfg)" class="text-woot-500 hover:underline text-xs">Save</button>
                <button @click="editing = null" class="text-slate-500 hover:underline text-xs">Cancel</button>
              </template>
              <button v-else @click="startEdit(cfg)" class="text-woot-500 hover:underline text-xs">Edit</button>
            </td>
          </tr>
          <tr v-if="!configs.length"><td colspan="3" class="px-4 py-8 text-center text-slate-400">No configs found</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
