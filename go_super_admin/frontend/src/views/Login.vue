<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const auth = useAuthStore()

const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

async function submit() {
  error.value = ''
  loading.value = true
  try {
    await auth.login(email.value, password.value)
    router.push('/super_admin')
  } catch (e) {
    error.value = e.response?.data?.error || 'Login failed'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="h-full w-full antialiased">
    <main class="flex flex-col bg-woot-25 min-h-screen w-full py-20 px-6">
      <section class="max-w-5xl mx-auto text-center">
        <div class="text-2xl font-bold text-woot-500">Chatwoot</div>
        <h2 class="mt-4 text-3xl font-medium text-slate-900">
          Howdy, admin 👋
        </h2>
      </section>
      <section class="bg-white shadow sm:mx-auto mt-11 sm:w-full sm:max-w-lg p-11 sm:shadow-lg sm:rounded-lg mb-8">
        <div v-if="error" class="rounded-md bg-red-500 p-4 text-white text-sm mb-5">
          {{ error }}
        </div>
        <form @submit.prevent="submit">
          <div class="mb-5">
            <label class="flex justify-between text-sm font-medium leading-6 text-slate-900">
              Email Address
            </label>
            <div class="mt-1">
              <input
                v-model="email" type="email" required autofocus
                placeholder="Email eg: someone@example.com"
                class="block w-full rounded-md border-0 px-3 py-3 appearance-none shadow-sm ring-1 ring-inset text-slate-900 placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-woot-500 text-sm leading-6 outline-none ring-slate-200"
              />
            </div>
          </div>
          <div class="mb-5">
            <label class="flex justify-between text-sm font-medium leading-6 text-slate-900">
              Password
            </label>
            <div class="mt-1">
              <input
                v-model="password" type="password" required
                placeholder="Password"
                class="block w-full rounded-md border-0 px-3 py-3 appearance-none shadow-sm ring-1 ring-inset text-slate-900 placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-woot-500 text-sm leading-6 outline-none ring-slate-200"
              />
            </div>
          </div>
          <button
            type="submit" :disabled="loading"
            class="flex items-center w-full justify-center rounded-md bg-woot-500 py-3 px-3 text-base font-medium text-white shadow-sm hover:bg-woot-600 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-woot-500 cursor-pointer disabled:opacity-50"
          >
            {{ loading ? 'Signing in...' : 'Login' }}
          </button>
        </form>
      </section>
    </main>
  </div>
</template>
