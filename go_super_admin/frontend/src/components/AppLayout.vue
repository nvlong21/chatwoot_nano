<script setup>
import { ref, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()
const settingsOpen = ref(false)

watch(() => route.path, (p) => {
  if (p.startsWith('/super_admin/app_config')) settingsOpen.value = true
}, { immediate: true })

function logout() {
  auth.logout()
  router.push('/super_admin/login')
}

const mainNavItems = [
  { label: 'Dashboard', path: '/super_admin', icon: 'ri-grid-line', exact: true },
  { label: 'Accounts', path: '/super_admin/accounts', icon: 'ri-building-4-line' },
  { label: 'Users', path: '/super_admin/users', icon: 'ri-user-follow-line' },
  { label: 'Platform Apps', path: '/super_admin/platform_apps', icon: 'ri-apps-2-line' },
  { label: 'Agent Bots', path: '/super_admin/agent_bots', icon: 'ri-robot-line' },
]

const settingsNavItems = [
  { label: 'General', path: '/super_admin/app_config', query: 'general' },
  { label: 'Email', path: '/super_admin/app_config', query: 'email' },
  { label: 'Messenger', path: '/super_admin/app_config', query: 'facebook' },
  { label: 'Instagram', path: '/super_admin/app_config', query: 'instagram' },
  { label: 'TikTok', path: '/super_admin/app_config', query: 'tiktok' },
  { label: 'Google', path: '/super_admin/app_config', query: 'google' },
  { label: 'Microsoft', path: '/super_admin/app_config', query: 'microsoft' },
  { label: 'Slack', path: '/super_admin/app_config', query: 'slack' },
  { label: 'WhatsApp Embedded', path: '/super_admin/app_config', query: 'whatsapp_embedded' },
  { label: 'Shopify', path: '/super_admin/app_config', query: 'shopify' },
  { label: 'Notion', path: '/super_admin/app_config', query: 'notion' },
  { label: 'Custom Branding', path: '/super_admin/app_config', query: 'custom_branding' },
]

const bottomNavItems = [
  { label: 'Instance Health', path: '/super_admin/instance_status', icon: 'ri-heart-pulse-line' },
  { label: 'Go Info', path: '/super_admin/settings', icon: 'ri-dashboard-line' },
]

function isActive(path, exact = false) {
  if (exact) return route.path === path
  return route.path.startsWith(path)
}

function isSettingsActive() {
  return route.path.startsWith('/super_admin/app_config')
}

function isSettingsItemActive(item) {
  return route.path === item.path && route.query.config === item.query
}
</script>

<template>
  <div class="flex h-screen bg-slate-25">
    <!-- Sidebar -->
    <aside class="w-56 border-r border-slate-100 flex flex-col shrink-0 bg-white" role="navigation">
      <!-- Logo -->
      <div class="flex items-center mx-4 mb-4 border-b border-slate-100 py-6">
        <div class="h-10 w-10 rounded-lg bg-woot-500 flex items-center justify-center text-white font-bold text-lg shrink-0">C</div>
        <div class="flex flex-col ml-3">
          <div class="text-sm text-slate-800">Chatwoot</div>
          <div class="text-xs text-slate-700 mt-0.5">Super Admin Console</div>
        </div>
      </div>

      <!-- Main nav -->
      <ul class="my-4 flex-1 overflow-y-auto">
        <li v-for="item in mainNavItems" :key="item.path" class="px-4 mb-1">
          <RouterLink
            :to="item.path"
            class="-ml-1 flex items-center px-2 py-1.5 rounded-lg text-sm transition-colors"
            :class="isActive(item.path, item.exact)
              ? 'text-woot-500 bg-slate-25'
              : 'text-slate-800 hover:text-woot-500 hover:bg-slate-25'"
          >
            <i :class="item.icon" class="text-base leading-none"></i>
            <span class="ml-2">{{ item.label }}</span>
          </RouterLink>
        </li>

        <!-- Settings collapsible -->
        <li class="px-4 mb-1">
          <div>
            <button
              @click="settingsOpen = !settingsOpen"
              class="-ml-1 w-full flex items-center px-2 py-1.5 rounded-lg text-sm transition-colors list-none"
              :class="isSettingsActive() || settingsOpen
                ? 'text-woot-500 bg-slate-25'
                : 'text-slate-800 hover:text-woot-500 hover:bg-slate-25'"
            >
              <i class="ri-settings-2-line text-base leading-none"></i>
              <span class="ml-2">Settings</span>
              <i
                class="ri-arrow-down-s-line ml-auto transition-transform duration-200"
                :class="settingsOpen ? 'rotate-180' : ''"
              ></i>
            </button>
            <ul v-if="settingsOpen" class="ml-4 mt-1">
              <li v-for="item in settingsNavItems" :key="item.query" class="px-4 mb-1">
                <RouterLink
                  :to="{ path: item.path, query: { config: item.query } }"
                  class="-ml-1 flex items-center px-2 py-1.5 rounded-lg text-sm transition-colors"
                  :class="isSettingsItemActive(item)
                    ? 'text-woot-500 bg-slate-25'
                    : 'text-slate-800 hover:text-woot-500 hover:bg-slate-25'"
                >
                  <span class="ml-2">{{ item.label }}</span>
                </RouterLink>
              </li>
            </ul>
          </div>
        </li>
      </ul>

      <!-- Bottom nav -->
      <ul class="my-4">
        <li v-for="item in bottomNavItems" :key="item.path" class="px-4 mb-1">
          <RouterLink
            :to="item.path"
            class="-ml-1 flex items-center px-2 py-1.5 rounded-lg text-sm transition-colors"
            :class="isActive(item.path)
              ? 'text-woot-500 bg-slate-25'
              : 'text-slate-800 hover:text-woot-500 hover:bg-slate-25'"
          >
            <i :class="item.icon" class="text-base leading-none"></i>
            <span class="ml-2">{{ item.label }}</span>
          </RouterLink>
        </li>
        <li class="px-4 mb-1">
          <button
            @click="logout"
            class="-ml-1 w-full flex items-center px-2 py-1.5 rounded-lg text-sm text-slate-800 hover:text-woot-500 hover:bg-slate-25 transition-colors"
          >
            <i class="ri-logout-circle-r-line text-base leading-none"></i>
            <span class="ml-2">Logout</span>
          </button>
        </li>
      </ul>
    </aside>

    <!-- Main content -->
    <main class="flex-1 overflow-y-auto p-8" role="main">
      <RouterView />
    </main>
  </div>
</template>
