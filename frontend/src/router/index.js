import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  { path: '/login', component: () => import('@/views/Login.vue'), meta: { public: true } },
  {
    path: '/',
    component: () => import('@/components/layout/AppLayout.vue'),
    children: [
      { path: '', redirect: '/dashboard' },
      { path: 'dashboard', component: () => import('@/views/Dashboard.vue') },
      { path: 'shops', component: () => import('@/views/shops/ShopsList.vue') },
      { path: 'shops/:id', component: () => import('@/views/shops/ShopDetail.vue') },
      { path: 'applications', component: () => import('@/views/applications/ApplicationsList.vue') },
      { path: 'applications/:id', component: () => import('@/views/applications/ApplicationDetail.vue') },
      { path: 'orders', component: () => import('@/views/orders/OrdersList.vue') },
      { path: 'credits', component: () => import('@/views/credits/Credits.vue') },
      { path: 'products', component: () => import('@/views/products/Products.vue') },
      { path: 'analytics', component: () => import('@/views/analytics/Analytics.vue') },
      { path: 'reports', component: () => import('@/views/reports/Reports.vue') },
      { path: 'settings', component: () => import('@/views/settings/Settings.vue') },
      { path: 'prospects', component: () => import('@/views/prospects/Prospects.vue') },
      { path: 'finance', component: () => import('@/views/finance/Finance.vue') },
    ],
  },
  { path: '/:pathMatch(.*)*', redirect: '/dashboard' },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('access_token')
  if (to.meta.public) return next()
  if (!token) return next('/login')
  next()
})

export default router
