import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import client from '../api/client'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('cw_token') || null)
  const user = ref(JSON.parse(localStorage.getItem('cw_user') || 'null'))
  const accountId = ref(localStorage.getItem('cw_account_id') || null)

  const isLoggedIn = computed(() => !!token.value)

  async function login(email, password) {
    const res = await client.post('/auth/login', { email, password })
    const data = res.data

    token.value = data.token
    user.value = data.user
    accountId.value = data.account_id ? String(data.account_id) : null

    localStorage.setItem('cw_token', data.token)
    localStorage.setItem('cw_user', JSON.stringify(data.user))
    if (data.account_id) {
      localStorage.setItem('cw_account_id', String(data.account_id))
    }
  }

  function logout() {
    token.value = null
    user.value = null
    accountId.value = null
    localStorage.clear()
  }

  return { token, user, accountId, isLoggedIn, login, logout }
})
