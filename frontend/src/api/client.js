import axios from 'axios'

// In production (Railway), VITE_API_URL = https://your-backend.railway.app
// In dev, empty → uses Vite proxy (localhost:5173 → localhost:8000)
const baseURL = import.meta.env.VITE_API_URL || '/'

const client = axios.create({
  baseURL,
  timeout: 30000,
})

client.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

client.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config
    if (error.response?.status === 401 && !original._retry) {
      original._retry = true
      const refreshToken = localStorage.getItem('refresh_token')
      if (refreshToken) {
        try {
          // Bare axios (no interceptors → no refresh recursion), but let axios
          // join the path to baseURL so a baseURL without a trailing slash works.
          const { data } = await axios.post('/api/auth/refresh', { refresh_token: refreshToken }, { baseURL })
          localStorage.setItem('access_token', data.access_token)
          original.headers.Authorization = `Bearer ${data.access_token}`
          return client(original)
        } catch {
          localStorage.removeItem('access_token')
          localStorage.removeItem('refresh_token')
          window.location.href = '/login'
        }
      } else {
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  }
)

export default client
