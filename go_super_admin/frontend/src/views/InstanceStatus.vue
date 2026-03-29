<script setup>
import { ref, onMounted } from 'vue'
import client from '../api/client'

const status = ref(null)

onMounted(async () => {
  const { data } = await client.get('/instance_status')
  status.value = data
})

function badge(val) {
  return val === 'ok' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
}
</script>

<template>
  <div class="max-w-2xl">
    <h1 class="text-2xl font-medium text-slate-800 mb-6">Instance Status</h1>

    <div v-if="status" class="space-y-4">
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="font-semibold text-slate-700 mb-3">Database</h2>
        <div class="flex items-center gap-2">
          <span :class="badge(status.db_status)" class="px-2 py-0.5 rounded-full text-xs font-medium">{{ status.db_status }}</span>
          <span v-if="status.db_error" class="text-red-600 text-sm">{{ status.db_error }}</span>
        </div>
      </div>

      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="font-semibold text-slate-700 mb-3">Redis</h2>
        <div class="flex items-center gap-2 mb-3">
          <span :class="badge(status.redis_status)" class="px-2 py-0.5 rounded-full text-xs font-medium">{{ status.redis_status }}</span>
          <span v-if="status.redis_error" class="text-red-600 text-sm">{{ status.redis_error }}</span>
        </div>
        <dl v-if="status.redis_info" class="grid grid-cols-2 gap-2 text-xs text-slate-600">
          <template v-for="(val, key) in {
            redis_version: status.redis_info?.redis_version,
            connected_clients: status.redis_info?.connected_clients,
            used_memory_human: status.redis_info?.used_memory_human,
            uptime_in_days: status.redis_info?.uptime_in_days,
          }" :key="key">
            <div v-if="val"><dt class="text-slate-400">{{ key }}</dt><dd>{{ val }}</dd></div>
          </template>
        </dl>
      </div>
    </div>
  </div>
</template>
