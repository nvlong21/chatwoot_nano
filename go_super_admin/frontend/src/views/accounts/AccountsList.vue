<script setup>
import { ref, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import client from '../../api/client'

const router = useRouter()
const accounts = ref([])
const meta = ref({})
const search = ref('')
const page = ref(1)

async function load() {
  const { data } = await client.get('/accounts', { params: { page: page.value, search: search.value } })
  accounts.value = data.data
  meta.value = data.meta
}

onMounted(load)
watch(page, load)

function doSearch() { page.value = 1; load() }

async function deleteAccount(id) {
  if (!confirm('Delete this account?')) return
  await client.delete(`/accounts/${id}`)
  load()
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-medium text-slate-800">Accounts</h1>
      <RouterLink to="/super_admin/accounts/new" class="bg-woot-500 text-white px-4 py-2 rounded text-sm hover:bg-woot-600">
        New Account
      </RouterLink>
    </div>

    <form @submit.prevent="doSearch" class="mb-4 flex gap-2">
      <input v-model="search" placeholder="Search accounts..." class="border border-slate-200 rounded px-3 py-1.5 text-sm w-64 focus:outline-none focus:ring-2 focus:ring-woot-500" />
      <button class="bg-slate-100 px-3 py-1.5 text-sm rounded border hover:bg-slate-200">Search</button>
    </form>

    <div class="bg-white rounded-lg shadow overflow-hidden">
      <table class="min-w-full divide-y divide-slate-100 text-sm">
        <thead class="bg-slate-25">
          <tr>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">ID</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Name</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Status</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Users</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Conversations</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="a in accounts" :key="a.id" class="hover:bg-slate-25">
            <td class="px-4 py-3 text-slate-400 text-xs">{{ a.id }}</td>
            <td class="px-4 py-3 font-medium text-slate-800">{{ a.name }}</td>
            <td class="px-4 py-3">
              <span :class="a.status === 0 ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'" class="px-2 py-0.5 rounded-full text-xs font-medium">
                {{ a.status === 0 ? 'active' : 'suspended' }}
              </span>
            </td>
            <td class="px-4 py-3 text-slate-600">{{ a.user_count }}</td>
            <td class="px-4 py-3 text-slate-600">{{ a.conversation_count }}</td>
            <td class="px-4 py-3 flex gap-3">
              <RouterLink :to="`/super_admin/accounts/${a.id}`" class="text-woot-500 hover:underline">View</RouterLink>
              <RouterLink :to="`/super_admin/accounts/${a.id}/edit`" class="text-slate-600 hover:underline">Edit</RouterLink>
              <button @click="deleteAccount(a.id)" class="text-red-500 hover:underline">Delete</button>
            </td>
          </tr>
          <tr v-if="!accounts.length">
            <td colspan="6" class="px-4 py-8 text-center text-slate-400">No accounts found</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="meta.total_pages > 1" class="flex items-center justify-between mt-4 text-sm text-slate-600">
      <span>Page {{ meta.page }} of {{ meta.total_pages }} ({{ meta.total_count }} total)</span>
      <div class="flex gap-2">
        <button v-if="page > 1" @click="page--" class="px-3 py-1 border rounded hover:bg-slate-25">Previous</button>
        <button v-if="page < meta.total_pages" @click="page++" class="px-3 py-1 border rounded hover:bg-slate-25">Next</button>
      </div>
    </div>
  </div>
</template>
