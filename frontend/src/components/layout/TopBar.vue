<template>
  <header class="topbar">
    <div style="display:flex; align-items:center; gap:8px; color:var(--text-muted); font-size:12px;">
      <span>Filby Coffee</span>
      <ChevronRight :size="12" />
      <span style="color:var(--text);">{{ pageTitle }}</span>
    </div>
    <div style="margin-left:auto; display:flex; align-items:center; gap:16px;">
      <div style="font-size:12px; color:var(--text-muted);">{{ formatDate(now) }}</div>
      <div style="width:1px; height:20px; background:var(--border);"></div>
      <div style="display:flex; align-items:center; gap:6px;">
        <div style="width:7px; height:7px; background:var(--success); border-radius:50%;"></div>
        <span style="font-size:12px; color:var(--text-secondary);">{{ authStore.user?.name }}</span>
      </div>
    </div>
  </header>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { ChevronRight } from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth.js'

const authStore = useAuthStore()
const route = useRoute()
const now = ref(new Date())
let timer

onMounted(() => { timer = setInterval(() => { now.value = new Date() }, 60000) })
onUnmounted(() => clearInterval(timer))

const pageTitles = {
  '/dashboard': 'Dashboard', '/shops': 'ຮ້ານກາເຟ', '/applications': 'ຄຳສະໝັກ',
  '/orders': 'ຄຳສັ່ງຊື້', '/credits': 'ສິນເຊື່ອ & ຊຳລະ', '/products': 'ສິນຄ້າ',
  '/analytics': 'Analytics', '/reports': 'ລາຍງານ', '/settings': 'ຕັ້ງຄ່າ',
}

const pageTitle = computed(() => {
  const path = '/' + route.path.split('/')[1]
  return pageTitles[path] || 'Dashboard'
})

function formatDate(d) {
  const day = String(d.getDate()).padStart(2, '0')
  const month = String(d.getMonth() + 1).padStart(2, '0')
  return `${day}/${month}/${d.getFullYear()}`
}
</script>
