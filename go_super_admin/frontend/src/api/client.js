import axios from 'axios'

const client = axios.create({ baseURL: '/super_admin/api' })

client.interceptors.request.use((config) => {
  const token = localStorage.getItem('super_admin_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

client.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('super_admin_token')
      window.location.href = '/super_admin/login'
    }
    return Promise.reject(err)
  },
)

export default client
