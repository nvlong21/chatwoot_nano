<script setup>
import { ref, onMounted, watch } from 'vue'
import client from '../../api/client'

const users = ref([])
const meta = ref({})
const search = ref('')
const page = ref(1)

async function load() {
  const { data } = await client.get('/users', { params: { page: page.value, search: search.value } })
  users.value = data.data
  meta.value = data.meta
}

onMounted(load)
watch(page, load)
function doSearch() { page.value = 1; load() }

async function deleteUser(id) {
  if (!confirm('Delete this user?')) return
  await client.delete(`/users/${id}`)
  load()
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-medium text-slate-800">Users</h1>
      <RouterLink to="/super_admin/users/new" class="bg-woot-500 text-white px-4 py-2 rounded text-sm hover:bg-woot-600">New User</RouterLink>
    </div>

    <form @submit.prevent="doSearch" class="mb-4 flex gap-2">
      <input v-model="search" placeholder="Search users..." class="border border-slate-200 rounded px-3 py-1.5 text-sm w-64 focus:outline-none focus:ring-2 focus:ring-woot-500" />
      <button class="bg-slate-100 px-3 py-1.5 text-sm rounded border hover:bg-slate-200">Search</button>
    </form>

    <div class="bg-white rounded-lg shadow overflow-hidden">
      <table class="min-w-full divide-y divide-slate-100 text-sm">
        <thead class="bg-slate-25">
          <tr>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">ID</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Name</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Email</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Type</th>
            <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="u in users" :key="u.id" class="hover:bg-slate-25">
            <td class="px-4 py-3 text-slate-400 text-xs">{{ u.id }}</td>
            <td class="px-4 py-3 font-medium text-slate-800">{{ u.name }}</td>
            <td class="px-4 py-3 text-slate-600">{{ u.email }}</td>
            <td class="px-4 py-3">
              <span :class="u.type === 'SuperAdmin' ? 'bg-purple-100 text-purple-700' : 'bg-slate-100 text-slate-600'" class="px-2 py-0.5 rounded-full text-xs">
                {{ u.type }}
              </span>
            </td>
            <td class="px-4 py-3 flex gap-3">
              <RouterLink :to="`/super_admin/users/${u.id}`" class="text-woot-500 hover:underline">View</RouterLink>
              <RouterLink :to="`/super_admin/users/${u.id}/edit`" class="text-slate-600 hover:underline">Edit</RouterLink>
              <button @click="deleteUser(u.id)" class="text-red-500 hover:underline">Delete</button>
            </td>
          </tr>
          <tr v-if="!users.length">
            <td colspan="5" class="px-4 py-8 text-center text-slate-400">No users found</td>
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
