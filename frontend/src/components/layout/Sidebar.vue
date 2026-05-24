<template>
  <aside class="sidebar">
    <!-- Logo -->
    <div style="padding: 20px 20px 16px; border-bottom: 1px solid var(--border);">
      <div style="display:flex; align-items:center; gap:10px;">
        <img src="/logo.png" alt="Filby Coffee" style="width:44px; height:44px; object-fit:contain;" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex'" />
        <div style="display:none; width:36px; height:36px; background:linear-gradient(135deg,var(--primary),var(--primary-deep)); border-radius:10px; align-items:center; justify-content:center;">
          <Coffee :size="18" color="#fff" />
        </div>
        <div>
          <div style="font-weight:700; font-size:15px; color:var(--cream);">Filby Coffee</div>
          <div style="font-size:10px; color:var(--text-muted);">Admin Dashboard</div>
        </div>
      </div>
    </div>

    <!-- Navigation -->
    <nav style="flex:1; padding: 12px 8px; overflow-y:auto;">
      <div v-for="group in navGroups" :key="group.label">
        <div style="font-size:10px; font-weight:600; color:var(--text-muted); text-transform:uppercase; letter-spacing:0.1em; padding:8px 12px 4px;">{{ group.label }}</div>
        <RouterLink
          v-for="item in group.items"
          :key="item.to"
          :to="item.to"
          custom
          v-slot="{ isActive, navigate }"
        >
          <div
            @click="navigate"
            :class="['nav-item', isActive && 'nav-item-active']"
            style="display:flex; align-items:center; gap:10px; padding:9px 12px; border-radius:8px; cursor:pointer; margin-bottom:2px; transition:all 0.15s; color: var(--text-secondary); font-size:13px;"
            :style="isActive ? 'color: var(--primary);' : ''"
            @mouseenter="e => !isActive && (e.currentTarget.style.background = 'var(--surface)')"
            @mouseleave="e => !isActive && (e.currentTarget.style.background = '')"
          >
            <component :is="item.icon" :size="15" />
            <span>{{ item.label }}</span>
            <span v-if="item.badge" style="margin-left:auto; background:rgba(232,133,74,0.2); color:var(--primary); font-size:10px; font-weight:700; padding:1px 6px; border-radius:10px;">{{ item.badge }}</span>
          </div>
        </RouterLink>
      </div>
    </nav>

    <!-- User info -->
    <div style="padding:12px; border-top:1px solid var(--border);">
      <div style="display:flex; align-items:center; gap:10px; padding:8px; border-radius:8px; background:var(--surface-2);">
        <div style="width:32px; height:32px; background:linear-gradient(135deg, var(--primary-deep), var(--primary)); border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:12px; font-weight:700; color:#fff;">
          {{ (authStore.user?.name || 'A').charAt(0).toUpperCase() }}
        </div>
        <div style="flex:1; min-width:0;">
          <div style="font-size:12px; font-weight:600; color:var(--text); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">{{ authStore.user?.name }}</div>
          <div style="font-size:10px; color:var(--text-muted);">{{ roleLabel(authStore.user?.role) }}</div>
        </div>
        <button @click="handleLogout" style="background:none; border:none; cursor:pointer; color:var(--text-muted); padding:4px;" title="ອອກຈາກລະບົບ">
          <LogOut :size="14" />
        </button>
      </div>
    </div>
  </aside>
</template>

<script setup>
import { RouterLink, useRouter } from 'vue-router'
import { Coffee, LayoutDashboard, Store, FileText, ShoppingBag, CreditCard, Package, BarChart2, FileBarChart, Settings, LogOut, ClipboardList } from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth.js'

const authStore = useAuthStore()
const router = useRouter()

const navGroups = [
  {
    label: 'ຫຼັກ',
    items: [
      { to: '/dashboard', label: 'ໜ້າຫຼັກ', icon: LayoutDashboard },
    ],
  },
  {
    label: 'ການດຳເນີນງານ',
    items: [
      { to: '/shops', label: 'ຮ້ານກາເຟ', icon: Store },
      { to: '/applications', label: 'ຄຳສະໝັກ', icon: FileText },
      { to: '/orders', label: 'ຄຳສັ່ງຊື້', icon: ShoppingBag },
      { to: '/credits', label: 'ສິນເຊື່ອ & ຊຳລະ', icon: CreditCard },
      { to: '/products', label: 'ສິນຄ້າ', icon: Package },
    ],
  },
  {
    label: 'ສຳຫຼວດ',
    items: [
      { to: '/prospects', label: 'ສຳຫຼວດຮ້ານ', icon: ClipboardList },
    ],
  },
  {
    label: 'ຂໍ້ມູນ',
    items: [
      { to: '/analytics', label: 'Analytics', icon: BarChart2 },
      { to: '/reports', label: 'ລາຍງານ', icon: FileBarChart },
    ],
  },
  {
    label: 'ລະບົບ',
    items: [
      { to: '/settings', label: 'ຕັ້ງຄ່າ', icon: Settings },
    ],
  },
]

function roleLabel(role) {
  return { super_admin: 'Super Admin', manager: 'ຜູ້ຈັດການ', support: 'Support', accountant: 'ນັກບັນຊີ' }[role] || role
}

async function handleLogout() {
  await authStore.logout()
  router.push('/login')
}
</script>
