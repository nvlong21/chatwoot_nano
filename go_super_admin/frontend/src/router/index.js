import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const routes = [
  { path: '/super_admin/login', component: () => import('../views/Login.vue'), meta: { public: true } },
  {
    path: '/super_admin',
    component: () => import('../components/AppLayout.vue'),
    children: [
      { path: '', component: () => import('../views/Dashboard.vue') },
      { path: 'accounts', component: () => import('../views/accounts/AccountsList.vue') },
      { path: 'accounts/new', component: () => import('../views/accounts/AccountForm.vue') },
      { path: 'accounts/:id', component: () => import('../views/accounts/AccountDetail.vue') },
      { path: 'accounts/:id/edit', component: () => import('../views/accounts/AccountForm.vue') },
      { path: 'users', component: () => import('../views/users/UsersList.vue') },
      { path: 'users/new', component: () => import('../views/users/UserForm.vue') },
      { path: 'users/:id', component: () => import('../views/users/UserDetail.vue') },
      { path: 'users/:id/edit', component: () => import('../views/users/UserForm.vue') },
      { path: 'access_tokens', component: () => import('../views/AccessTokens.vue') },
      { path: 'agent_bots', component: () => import('../views/AgentBots.vue') },
      { path: 'platform_apps', component: () => import('../views/PlatformApps.vue') },
      { path: 'installation_configs', component: () => import('../views/InstallationConfigs.vue') },
      { path: 'app_config', component: () => import('../views/AppConfig.vue') },
      { path: 'instance_status', component: () => import('../views/InstanceStatus.vue') },
      { path: 'settings', component: () => import('../views/Settings.vue') },
    ],
  },
  { path: '/:pathMatch(.*)*', redirect: '/super_admin' },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to) => {
  const auth = useAuthStore()
  if (!to.meta.public && !auth.isLoggedIn) {
    return '/super_admin/login'
  }
  if (to.path === '/super_admin/login' && auth.isLoggedIn) {
    return '/super_admin'
  }
})

export default router
