<script setup>
import { ref, onMounted } from 'vue'
import client from '../api/client'

const stats = ref(null)

onMounted(async () => {
  const { data } = await client.get('/dashboard')
  stats.value = data
})
</script>

<template>
  <div>
    <h1 class="text-2xl font-medium text-slate-800 mb-6">Dashboard</h1>

    <div v-if="stats" class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
      <div v-for="(item) in [
        { label: 'Accounts', value: stats.account_count },
        { label: 'Users', value: stats.user_count },
        { label: 'Inboxes', value: stats.inbox_count },
        { label: 'Conversations', value: stats.conversation_count },
      ]" :key="item.label" class="bg-white rounded-lg shadow p-5">
        <p class="text-sm text-slate-500">{{ item.label }}</p>
        <p class="text-3xl font-bold text-slate-800 mt-1">{{ item.value?.toLocaleString() }}</p>
      </div>
    </div>

    <div v-if="stats?.daily_conversations?.length" class="bg-white rounded-lg shadow p-6">
      <h2 class="text-base font-semibold text-slate-800 mb-4">Conversations – last 30 days</h2>
      <div class="space-y-1.5">
        <div v-for="d in stats.daily_conversations" :key="d.date" class="flex items-center gap-3 text-sm">
          <span class="w-20 text-slate-500 shrink-0 text-xs">{{ d.date }}</span>
          <div class="flex-1 bg-slate-100 rounded h-4 overflow-hidden">
            <div
              class="bg-woot-500 h-4 rounded"
              :style="{ width: Math.min(d.count * 4, 100) + '%' }"
            />
          </div>
          <span class="w-8 text-right text-slate-700 text-xs">{{ d.count }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
