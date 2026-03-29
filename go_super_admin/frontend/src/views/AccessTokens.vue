<script setup>
import { ref, onMounted, watch } from 'vue'
import client from '../api/client'

const tokens = ref([])
const meta = ref({})
const page = ref(1)
const ownerType = ref('')

async function load() {
  const { data } = await client.get('/access_tokens', { params: { page: page.value, owner_type: ownerType.value } })
  tokens.value = data.data
  meta.value = data.meta
}

onMounted(load)
watch([page, ownerType], load)
</script>

<template>
  <div>
    <h1 class="text-2xl font-medium text-slate-800 mb-6">Access Tokens</h1>

    <div class="mb-4 flex gap-2">
      <select v-model="ownerType" class="border border-slate-200 rounded px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-woot-500">
        <option value="">All types</option>
        <option value="User">User</option>
        <option value="AgentBot">AgentBot</option>
        <option value="PlatformApp">PlatformApp</option>
      </select>
    </div>

    <div class="bg-white rounded-lg shadow overflow-hidden">
      <table class="min-w-full divide-y divide-slate-100 text-sm">
        <thead class="bg-slate-25">
          <tr>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">ID</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Owner</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Token</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Created</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="t in tokens" :key="t.id" class="hover:bg-slate-25">
            <td class="px-4 py-3 text-slate-400 text-xs">{{ t.id }}</td>
            <td class="px-4 py-3 text-slate-600">{{ t.owner_type }} #{{ t.owner_id }}</td>
            <td class="px-4 py-3 font-mono text-xs text-slate-500">{{ t.token?.slice(0, 20) }}...</td>
            <td class="px-4 py-3 text-slate-500 text-xs">{{ new Date(t.created_at).toLocaleDateString() }}</td>
          </tr>
          <tr v-if="!tokens.length">
            <td colspan="4" class="px-4 py-8 text-center text-slate-400">No tokens found</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="meta.total_pages > 1" class="flex items-center justify-between mt-4 text-sm text-slate-600">
      <span>Page {{ meta.page }} of {{ meta.total_pages }}</span>
      <div class="flex gap-2">
        <button v-if="page > 1" @click="page--" class="px-3 py-1 border rounded hover:bg-slate-25">Previous</button>
        <button v-if="page < meta.total_pages" @click="page++" class="px-3 py-1 border rounded hover:bg-slate-25">Next</button>
      </div>
    </div>
  </div>
</template>
