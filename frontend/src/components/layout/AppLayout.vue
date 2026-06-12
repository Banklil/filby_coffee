<template>
  <div style="display:flex; min-height:100vh;">
    <Sidebar />
    <div class="flex-1 w-full flex flex-col" style="margin-left:240px;">
      <TopBar />
      <main class="main-content">
        <RouterView />
      </main>
    </div>

    <!-- ── Real-time order notifications ─────────────────────────────── -->
    <Teleport to="body">
      <div style="position:fixed; top:20px; right:20px; z-index:9999; display:flex; flex-direction:column; gap:10px; width:340px; pointer-events:none;">
        <TransitionGroup name="notif">
          <div
            v-for="n in notifications"
            :key="n._id"
            style="pointer-events:auto; background:#141b2d; border:1px solid rgba(232,133,74,0.5); border-left:4px solid #e8854a; border-radius:12px; padding:16px; box-shadow:0 8px 40px rgba(0,0,0,0.6); cursor:default;"
          >
            <!-- Header -->
            <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:10px;">
              <div style="display:flex; align-items:center; gap:8px;">
                <span style="font-size:18px;">🛒</span>
                <span style="font-size:12px; font-weight:700; color:#e8854a; text-transform:uppercase; letter-spacing:0.05em;">
                  {{ n.payment_method === 'qr' ? 'ສັ່ງຊື້ (QR) ໃໝ່!' : 'ສັ່ງຊື້ໃໝ່!' }}
                </span>
              </div>
              <button @click="dismiss(n._id)" style="background:none; border:none; cursor:pointer; color:#6b7fa3; font-size:16px; line-height:1; padding:2px 4px;" title="ປິດ">✕</button>
            </div>

            <!-- Body -->
            <div style="margin-bottom:12px;">
              <div style="font-size:15px; font-weight:700; color:#e8eaf6; margin-bottom:3px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">
                {{ n.shop_name || 'ລູກຄ້າ' }}
              </div>
              <div style="font-size:12px; color:#8899bb; margin-bottom:6px;">
                {{ n.product_name }} · {{ n.quantity }} {{ n.unit || 'kg' }}
              </div>
              <div style="font-size:20px; font-weight:800; color:#e8854a;">
                {{ Number(n.total_price).toLocaleString() }}
                <span style="font-size:12px; font-weight:400; color:#8899bb;">ກີບ</span>
              </div>
            </div>

            <!-- Progress bar (auto-dismiss timer) -->
            <div style="height:2px; background:rgba(255,255,255,0.1); border-radius:2px; margin-bottom:12px; overflow:hidden;">
              <div
                :style="{ width: n._progress + '%', background: '#e8854a', height: '100%', transition: 'width 1s linear' }"
              ></div>
            </div>

            <!-- Actions -->
            <div style="display:flex; gap:8px;">
              <button
                @click="goTo(n)"
                style="flex:1; background:#e8854a; color:#fff; border:none; border-radius:8px; padding:9px; font-size:12px; font-weight:700; cursor:pointer; transition:opacity 0.15s;"
                @mouseenter="e => e.currentTarget.style.opacity='0.85'"
                @mouseleave="e => e.currentTarget.style.opacity='1'"
              >
                {{ n.payment_method === 'qr' ? '✓ ໄປຢືນຢັນ' : '👁 ເບິ່ງ Order' }}
              </button>
              <button
                @click="dismiss(n._id)"
                style="background:rgba(255,255,255,0.07); color:#8899bb; border:none; border-radius:8px; padding:9px 14px; font-size:12px; cursor:pointer; transition:background 0.15s;"
                @mouseenter="e => e.currentTarget.style.background='rgba(255,255,255,0.12)'"
                @mouseleave="e => e.currentTarget.style.background='rgba(255,255,255,0.07)'"
              >ປິດ</button>
            </div>
          </div>
        </TransitionGroup>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { RouterView } from 'vue-router'
import Sidebar from './Sidebar.vue'
import TopBar from './TopBar.vue'
import { useSocket } from '@/composables/useSocket.js'

const router = useRouter()
const { connect, on, off } = useSocket()

const notifications = ref([])
let nextId = 0

const DISMISS_MS = 20000  // 20s auto-dismiss

function addNotification(payload) {
  const id = ++nextId
  notifications.value.unshift({ ...payload, _id: id, _progress: 100 })

  // Tick down progress bar every second
  const interval = setInterval(() => {
    const n = notifications.value.find(x => x._id === id)
    if (!n) { clearInterval(interval); return }
    n._progress = Math.max(0, n._progress - (100 / (DISMISS_MS / 1000)))
  }, 1000)

  // Auto dismiss
  setTimeout(() => {
    clearInterval(interval)
    dismiss(id)
  }, DISMISS_MS)
}

function dismiss(id) {
  notifications.value = notifications.value.filter(n => n._id !== id)
}

function goTo(n) {
  dismiss(n._id)
  router.push(n.payment_method === 'qr' ? '/payment' : '/orders')
}

onMounted(() => {
  connect()
  on('new_bean_order', addNotification)
})

onUnmounted(() => {
  off('new_bean_order')
})
</script>

<style scoped>
.notif-enter-active { transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1); }
.notif-leave-active { transition: all 0.25s ease-in; }
.notif-enter-from   { opacity: 0; transform: translateX(110%) scale(0.9); }
.notif-leave-to     { opacity: 0; transform: translateX(110%); }
</style>
