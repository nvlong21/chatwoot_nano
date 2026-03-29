<script setup>
import { ref, onMounted } from 'vue'
import client from '../api/client'

const settings = ref(null)

onMounted(async () => {
  const { data } = await client.get('/settings')
  settings.value = data
})

async function refresh() {
  await client.post('/settings/refresh')
  settings.value = null
  const { data } = await client.get('/settings')
  settings.value = data
}
</script>

<template>
  <div>
    <!-- Page header (matches Ruby Settings header style) -->
    <header class="flex items-center border-b border-slate-100 pb-4 mb-6">
      <div class="border border-slate-200 mr-4 p-2 rounded-full text-slate-600">
        <i class="ri-settings-2-line text-xl leading-none"></i>
      </div>
      <div>
        <h1 class="text-base font-medium text-slate-800">Settings</h1>
        <p class="text-sm text-slate-500 mt-0.5">Go service runtime information and controls</p>
      </div>
    </header>

    <!-- Server info card -->
    <div v-if="settings" class="outline outline-1 outline-slate-200 rounded-lg p-4 mb-4 shadow-sm">
      <div class="flex items-start justify-between flex-col md:flex-row md:items-center">
        <div class="flex flex-col gap-1">
          <h2 class="text-sm font-medium text-slate-800">Server Runtime</h2>
          <p class="text-sm text-slate-500">Go service information</p>
        </div>
        <button @click="refresh" class="mt-3 md:mt-0 flex gap-1 items-center bg-transparent shadow-sm h-9 hover:text-slate-800 hover:bg-slate-50 outline outline-1 outline-slate-200 rounded text-slate-600 font-medium px-3 py-2 text-sm focus:outline-none">
          <i class="ri-refresh-line"></i>
          <span class="ml-1">Refresh</span>
        </button>
      </div>
      <dl class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-3 text-sm border-t border-slate-100 pt-4">
        <div class="flex flex-col">
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">Go Version</dt>
          <dd class="font-medium text-slate-800 font-mono">{{ settings.go_version }}</dd>
        </div>
        <div class="flex flex-col">
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">OS / Architecture</dt>
          <dd class="font-medium text-slate-800 font-mono">{{ settings.go_os }} / {{ settings.go_arch }}</dd>
        </div>
        <div class="flex flex-col">
          <dt class="text-xs text-slate-500 uppercase font-medium mb-1">CPU Cores</dt>
          <dd class="font-medium text-slate-800 font-mono">{{ settings.num_cpu }}</dd>
        </div>
      </dl>
    </div>

    <!-- Need help section -->
    <div class="outline outline-1 outline-slate-200 rounded-lg p-4 shadow-sm flex items-start md:items-center flex-col md:flex-row">
      <div class="flex flex-col flex-grow gap-1">
        <h2 class="text-sm font-medium text-slate-800">Need help?</h2>
        <p class="text-sm text-slate-500">Do you face any issues? We are here to help.</p>
      </div>
      <a href="https://discord.gg/cJXdrwS" target="_blank" rel="noopener noreferrer">
        <button class="mt-3 md:mt-0 flex gap-1 items-center h-9 bg-violet-500 hover:bg-violet-600 text-white border border-violet-600 rounded font-medium px-3 py-2 text-sm focus:outline-none">
          <i class="ri-discord-line"></i>
          <span class="ml-1">Community Support</span>
        </button>
      </a>
    </div>
  </div>
</template>
