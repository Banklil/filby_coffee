<template>
  <div>
    <div style="margin-bottom:24px;">
      <h1 style="font-family:'Noto Serif Lao', serif; font-size:20px; font-weight:700; color:var(--cream);">ຄຳສັ່ງຊື້</h1>
      <p style="font-size:13px; color:var(--text-muted);">ທັງໝົດ {{ total }} ຄຳສັ່ງ</p>
    </div>

    <!-- Status filter tabs -->
    <div class="tab-nav" style="margin-bottom:0;">
      <button v-for="tab in statusTabs" :key="tab.key" class="tab-btn" :class="filterStatus === tab.key && 'active'" @click="changeStatus(tab.key)">{{ tab.label }}</button>
    </div>

    <div class="card" style="padding:0; overflow:hidden; border-top-left-radius:0;">
      <div class="table-wrapper">
        <table class="table">
          <thead>
            <tr>
              <th>Order ID</th>
              <th>ຮ້ານ</th>
              <th>ຈຳນວນ</th>
              <th>ວິທີຈ່າຍ</th>
              <th>ວັນຄົບກຳນົດ</th>
              <th>ສະຖານະ</th>
              <th>ວັນທີ</th>
              <th>ການດຳເນີນການ</th>
            </tr>
          </thead>
          <tbody>
            <template v-if="loading">
              <tr v-for="i in 8" :key="i"><td colspan="8"><div class="skeleton" style="height:18px;"></div></td></tr>
            </template>
            <template v-else-if="orders.length">
              <tr v-for="o in orders" :key="o.id" @click="openDetail(o)">
                <td class="num" style="color:var(--primary); font-size:12px;">{{ o.order_id }}</td>
                <td style="font-size:12px;">Shop #{{ o.shop_id }}</td>
                <td class="num">{{ formatCurrency(o.amount) }}</td>
                <td>{{ o.payment_method || '-' }}</td>
                <td :style="isOverdue(o) ? 'color:var(--danger);' : ''" class="num" style="font-size:12px;">{{ o.payment_due_date ? formatDate(o.payment_due_date) : '-' }}</td>
                <td><span :class="statusClass(o.status)">{{ statusLabel(o.status) }}</span></td>
                <td style="font-size:12px;">{{ formatDate(o.created_at) }}</td>
                <td @click.stop>
                  <div style="display:flex; gap:4px;">
                    <button v-if="o.status === 'confirmed'" class="btn btn-sm btn-ghost" style="font-size:11px;" @click.stop="quickStatus(o, 'shipping')">ສົ່ງ</button>
                    <button v-if="o.status === 'shipping'" class="btn btn-sm btn-ghost" style="font-size:11px;" @click.stop="quickStatus(o, 'delivered')">ຮັບ</button>
                  </div>
                </td>
              </tr>
            </template>
            <tr v-else>
              <td colspan="8">
                <div class="empty-state">
                  <div class="empty-icon"><ShoppingBag :size="24" color="var(--text-muted)" /></div>
                  <div style="font-weight:600; color:var(--text-secondary);">ບໍ່ມີຄຳສັ່ງຊື້</div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div style="display:flex; align-items:center; justify-content:space-between; padding:14px 20px; border-top:1px solid var(--border);">
        <span style="font-size:12px; color:var(--text-muted);">ສະແດງ {{ orders.length }} ຈາກ {{ total }}</span>
        <div class="pagination">
          <button class="page-btn" :disabled="page <= 1" @click="load(page-1)"><ChevronLeft :size="14" /></button>
          <button v-for="p in visiblePages" :key="p" class="page-btn" :class="p===page&&'active'" @click="load(p)">{{ p }}</button>
          <button class="page-btn" :disabled="page>=totalPages" @click="load(page+1)"><ChevronRight :size="14" /></button>
        </div>
      </div>
    </div>
  </div>

  <!-- Order Detail Modal -->
  <div v-if="selectedOrder" class="modal-overlay" @click.self="selectedOrder = null">
    <div class="modal" style="max-width:560px;">
      <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:16px;">
        <div>
          <span class="num" style="color:var(--primary); font-size:14px; font-weight:700;">{{ selectedOrder.order_id }}</span>
          <span :class="statusClass(selectedOrder.status)" style="margin-left:10px;">{{ statusLabel(selectedOrder.status) }}</span>
        </div>
        <button @click="selectedOrder = null" style="background:none; border:none; color:var(--text-muted); cursor:pointer;"><X :size="16" /></button>
      </div>

      <div style="margin-bottom:16px;">
        <div class="input-label">ຍອດ</div>
        <div class="num" style="font-size:20px; font-weight:700; color:var(--primary);">{{ formatCurrency(selectedOrder.amount) }}</div>
      </div>

      <div class="form-row" style="margin-bottom:16px;">
        <div><div class="input-label">ວິທີຈ່າຍ</div><div>{{ selectedOrder.payment_method }}</div></div>
        <div><div class="input-label">ວັນຄົບກຳນົດ</div><div class="num">{{ formatDate(selectedOrder.payment_due_date) }}</div></div>
        <div><div class="input-label">Tracking</div><div class="num">{{ selectedOrder.tracking_number || '-' }}</div></div>
        <div><div class="input-label">ທີ່ຢູ່ສົ່ງ</div><div>{{ selectedOrder.shipping_address || '-' }}</div></div>
      </div>

      <div v-if="selectedOrder.status !== 'delivered' && selectedOrder.status !== 'cancelled'" style="display:flex; gap:8px; margin-top:16px; flex-wrap:wrap;">
        <select v-model="newStatus" class="input" style="flex:1;">
          <option v-for="s in allowedStatuses" :key="s.value" :value="s.value">{{ s.label }}</option>
        </select>
        <input v-model="trackingNumber" class="input" style="flex:1;" placeholder="Tracking number (ຖ້າມີ)" />
        <button class="btn btn-primary" @click="updateStatus">ອັບເດດ</button>
        <button class="btn btn-danger btn-sm" @click="openCancel">ຍົກເລີກ</button>
      </div>
    </div>
  </div>

  <!-- Cancel Modal -->
  <div v-if="showCancelModal" class="modal-overlay" @click.self="showCancelModal = false">
    <div class="modal">
      <h3 style="font-size:15px; font-weight:700; margin-bottom:16px; color:var(--danger);">ຍົກເລີກຄຳສັ່ງຊື້?</h3>
      <div class="form-group">
        <label class="input-label">ເຫດຜົນ</label>
        <input v-model="cancelReason" class="input" placeholder="ເຫດຜົນ..." />
      </div>
      <div style="display:flex; gap:10px; justify-content:flex-end;">
        <button class="btn btn-ghost" @click="showCancelModal = false">ກັບຄືນ</button>
        <button class="btn btn-danger" @click="handleCancel">ຢືນຢັນ ຍົກເລີກ</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ShoppingBag, ChevronLeft, ChevronRight, X } from 'lucide-vue-next'
import { ordersApi } from '@/api/index.js'
import { useToastStore } from '@/stores/toast.js'
import { formatCurrency, formatDate, statusLabel, statusClass } from '@/utils/format.js'

const toast = useToastStore()
const orders = ref([])
const total = ref(0)
const totalPages = ref(1)
const page = ref(1)
const loading = ref(true)
const filterStatus = ref('')
const selectedOrder = ref(null)
const newStatus = ref('')
const trackingNumber = ref('')
const showCancelModal = ref(false)
const cancelReason = ref('')

const statusTabs = [
  { key: '', label: 'ທັງໝົດ' },
  { key: 'pending', label: 'ລໍຖ້າ' },
  { key: 'confirmed', label: 'ຢືນຢັນ' },
  { key: 'shipping', label: 'ກຳລັງສົ່ງ' },
  { key: 'delivered', label: 'ສົ່ງແລ້ວ' },
  { key: 'cancelled', label: 'ຍົກເລີກ' },
]

const allowedStatuses = computed(() => {
  const all = [
    { value: 'pending', label: 'ລໍຖ້າ' },
    { value: 'confirmed', label: 'ຢືນຢັນ' },
    { value: 'shipping', label: 'ກຳລັງສົ່ງ' },
    { value: 'delivered', label: 'ສົ່ງແລ້ວ' },
  ]
  return all
})

const visiblePages = computed(() => {
  const pages = []
  const start = Math.max(1, page.value - 2)
  for (let i = start; i <= Math.min(totalPages.value, start + 4); i++) pages.push(i)
  return pages
})

function isOverdue(o) {
  if (!o.payment_due_date || o.paid_at) return false
  return new Date(o.payment_due_date) < new Date()
}

async function load(p = 1) {
  loading.value = true
  page.value = p
  const { data } = await ordersApi.list({ page: p, limit: 50, status: filterStatus.value || undefined })
  orders.value = data.items
  total.value = data.total
  totalPages.value = data.pages
  loading.value = false
}

function changeStatus(s) { filterStatus.value = s; load(1) }

function openDetail(order) {
  selectedOrder.value = order
  newStatus.value = order.status
  trackingNumber.value = order.tracking_number || ''
}

async function quickStatus(order, status) {
  await ordersApi.updateStatus(order.id, { status })
  order.status = status
  toast.success(`ອັບເດດ: ${statusLabel(status)}`)
}

async function updateStatus() {
  await ordersApi.updateStatus(selectedOrder.value.id, { status: newStatus.value, tracking_number: trackingNumber.value })
  selectedOrder.value.status = newStatus.value
  selectedOrder.value.tracking_number = trackingNumber.value
  toast.success('ອັບເດດສະຖານະສຳເລັດ')
}

function openCancel() { showCancelModal.value = true }

async function handleCancel() {
  await ordersApi.cancel(selectedOrder.value.id, { reason: cancelReason.value })
  selectedOrder.value.status = 'cancelled'
  showCancelModal.value = false
  selectedOrder.value = null
  toast.success('ຍົກເລີກຄຳສັ່ງຊື້ແລ້ວ')
}

onMounted(() => load())
</script>
