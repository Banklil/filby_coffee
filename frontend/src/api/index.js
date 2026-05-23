import client from './client.js'

// Auth
export const authApi = {
  login: (data) => client.post('/api/auth/login', data),
  refresh: (data) => client.post('/api/auth/refresh', data),
  logout: () => client.post('/api/auth/logout'),
  me: () => client.get('/api/auth/me'),
  passwordReset: (email) => client.post('/api/auth/password-reset', { email }),
}

// Dashboard
export const dashboardApi = {
  kpis: () => client.get('/api/dashboard/kpis'),
  recent: () => client.get('/api/dashboard/recent'),
  creditTrend: (days = 30) => client.get(`/api/dashboard/charts/credit-trend?days=${days}`),
  topShops: (limit = 10) => client.get(`/api/dashboard/charts/top-shops?limit=${limit}`),
}

// Shops
export const shopsApi = {
  list: (params) => client.get('/api/shops', { params }),
  get: (id) => client.get(`/api/shops/${id}`),
  update: (id, data) => client.put(`/api/shops/${id}`, data),
  suspend: (id) => client.post(`/api/shops/${id}/suspend`),
  activate: (id) => client.post(`/api/shops/${id}/activate`),
  updateCreditLimit: (id, data) => client.put(`/api/shops/${id}/credit-limit`, data),
  orders: (id, params) => client.get(`/api/shops/${id}/orders`, { params }),
  payments: (id, params) => client.get(`/api/shops/${id}/payments`, { params }),
  stats: (id) => client.get(`/api/shops/${id}/stats`),
}

// Applications
export const applicationsApi = {
  list: (params) => client.get('/api/applications', { params }),
  get: (id) => client.get(`/api/applications/${id}`),
  approve: (id, data) => client.post(`/api/applications/${id}/approve`, data),
  reject: (id, data) => client.post(`/api/applications/${id}/reject`, data),
  requestInfo: (id, data) => client.post(`/api/applications/${id}/request-info`, data),
}

// Orders
export const ordersApi = {
  list: (params) => client.get('/api/orders', { params }),
  get: (id) => client.get(`/api/orders/${id}`),
  updateStatus: (id, data) => client.put(`/api/orders/${id}/status`, data),
  cancel: (id, data) => client.post(`/api/orders/${id}/cancel`, data),
  invoice: (id) => client.get(`/api/orders/${id}/invoice`, { responseType: 'blob' }),
}

// Credits
export const creditsApi = {
  overview: () => client.get('/api/credits/overview'),
  dueSoon: (days = 7) => client.get(`/api/credits/due-soon?days=${days}`),
  overdue: () => client.get('/api/credits/overdue'),
  recordPayment: (data) => client.post('/api/credits/payment', data),
}

// Products
export const productsApi = {
  list: () => client.get('/api/products'),
  create: (formData) => client.post('/api/products', formData, { headers: { 'Content-Type': 'multipart/form-data' } }),
  update: (id, data) => client.put(`/api/products/${id}`, data),
  delete: (id) => client.delete(`/api/products/${id}`),
  updateStock: (id, data) => client.post(`/api/products/${id}/stock`, data),
}

// Analytics
export const analyticsApi = {
  revenue: (days = 90) => client.get(`/api/analytics/revenue?days=${days}`),
  topProducts: (limit = 10) => client.get(`/api/analytics/top-products?limit=${limit}`),
  topShops: (limit = 10) => client.get(`/api/analytics/top-shops?limit=${limit}`),
  geography: () => client.get('/api/analytics/geography'),
  cohort: () => client.get('/api/analytics/cohort'),
}

// Reports
export const reportsApi = {
  exportOrders: () => client.get('/api/reports/orders.xlsx', { responseType: 'blob' }),
  exportPayments: () => client.get('/api/reports/payments.xlsx', { responseType: 'blob' }),
  shopStatement: (shopId, month) => client.get(`/api/reports/shop/${shopId}/statement?month=${month}`, { responseType: 'blob' }),
}

// Settings
export const settingsApi = {
  listAdmins: () => client.get('/api/admins'),
  createAdmin: (data) => client.post('/api/admins', data),
  updateAdmin: (id, data) => client.put(`/api/admins/${id}`, data),
  deleteAdmin: (id) => client.delete(`/api/admins/${id}`),
  auditLogs: (params) => client.get('/api/audit-logs', { params }),
}
