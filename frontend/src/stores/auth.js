import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { authApi } from '@/api/index.js'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(JSON.parse(localStorage.getItem('user') || 'null'))
  const loading = ref(false)
  const error = ref(null)

  const isAuthenticated = computed(() => !!user.value && !!localStorage.getItem('access_token'))
  const isAdmin = computed(() => user.value?.role === 'super_admin')
  const isManager = computed(() => ['super_admin', 'manager'].includes(user.value?.role))

  async function login(email, password) {
    loading.value = true
    error.value = null
    try {
      const { data } = await authApi.login({ email, password })
      localStorage.setItem('access_token', data.access_token)
      localStorage.setItem('refresh_token', data.refresh_token)
      localStorage.setItem('user', JSON.stringify(data.user))
      user.value = data.user
      return true
    } catch (err) {
      error.value = err.response?.data?.detail || 'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ'
      return false
    } finally {
      loading.value = false
    }
  }

  async function logout() {
    try { await authApi.logout() } catch {}
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('user')
    user.value = null
  }

  async function fetchMe() {
    try {
      const { data } = await authApi.me()
      user.value = data
      localStorage.setItem('user', JSON.stringify(data))
    } catch {}
  }

  return { user, loading, error, isAuthenticated, isAdmin, isManager, login, logout, fetchMe }
})
