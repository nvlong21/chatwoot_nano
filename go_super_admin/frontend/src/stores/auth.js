import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import client from '../api/client'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('super_admin_token'))
  const user = ref(JSON.parse(localStorage.getItem('super_admin_user') || 'null'))

  const isLoggedIn = computed(() => !!token.value)

  async function login(email, password) {
    const { data } = await client.post('/auth/login', { email, password })
    token.value = data.token
    user.value = data.user
    localStorage.setItem('super_admin_token', data.token)
    localStorage.setItem('super_admin_user', JSON.stringify(data.user))
  }

  function logout() {
    token.value = null
    user.value = null
    localStorage.removeItem('super_admin_token')
    localStorage.removeItem('super_admin_user')
  }

  return { token, user, isLoggedIn, login, logout }
})
