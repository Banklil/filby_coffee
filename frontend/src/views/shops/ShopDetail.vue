<template>
  <div v-if="loading">
    <div class="skeleton" style="height:120px; margin-bottom:16px;"></div>
    <div class="skeleton" style="height:400px;"></div>
  </div>

  <div v-else-if="shop">
    <!-- Header -->
    <div class="card" style="margin-bottom:16px;">
      <div style="display:flex; align-items:flex-start; gap:20px; flex-wrap:wrap;">
        <div style="width:60px; height:60px; background:linear-gradient(135deg, var(--primary-deep), var(--primary)); border-radius:14px; display:flex; align-items:center; justify-content:center; font-size:22px; font-weight:700; color:#fff;">
          {{ shop.name.charAt(0) }}
        </div>
        <div style="flex:1;">
          <div style="display:flex; align-items:center; gap:10px; flex-wrap:wrap;">
            <h1 style=" font-size:18px; font-weight:700; color:var(--cream);">{{ shop.name }}</h1>
            <span :class="statusClass(shop.status)">{{ statusLabel(shop.status) }}</span>
            <span :class="tierClass(shop.tier)" style="font-size:12px; font-weight:700;">★ {{ tierLabel(shop.tier) }}</span>
          </div>
          <div style="display:flex; gap:20px; margin-top:8px; flex-wrap:wrap;">
            <span style="font-size:12px; color:var(--text-muted);"><span style="font-family:Manrope;">{{ shop.shop_id }}</span></span>
            <span style="font-size:12px; color:var(--text-muted);">👤 {{ shop.owner_name }}</span>
            <span style="font-size:12px; color:var(--text-muted);">📞 {{ shop.phone }}</span>
            <span style="font-size:12px; color:var(--text-muted);">📍 {{ shop.province }}</span>
          </div>
          <!-- Credit bar -->
          <div style="margin-top:12px;">
            <div style="display:flex; justify-content:space-between; margin-bottom:4px;">
              <span style="font-size:11px; color:var(--text-muted);">ສິນເຊື່ອທີ່ໃຊ້</span>
              <span class="num" style="font-size:11px; color:var(--text-secondary);">{{ formatCurrency(shop.credit_used) }} / {{ formatCurrency(shop.credit_limit) }}</span>
            </div>
            <div style="height:6px; background:var(--surface-3); border-radius:3px;">
              <div :style="`height:100%; border-radius:3px; width:${Math.min(100, shop.credit_limit ? (shop.credit_used/shop.credit_limit)*100 : 0)}%; background:var(--primary); transition:width 0.3s;`"></div>
            </div>
          </div>
        </div>
        <!-- Actions -->
        <div style="display:flex; gap:8px; flex-wrap:wrap;">
          <button v-if="shop.status === 'active'" class="btn btn-danger btn-sm" @click="showSuspendModal = true">Suspend</button>
          <button v-else class="btn btn-sm" style="background:rgba(110,231,167,0.15); color:var(--success); border:none;" @click="handleActivate">ເປີດໃໝ່</button>
          <button class="btn btn-ghost btn-sm" @click="showCreditModal = true"><CreditCard :size="13" /> ແກ້ໄຂສິນເຊື່ອ</button>
          <button class="btn btn-ghost btn-sm" @click="router.back()"><ArrowLeft :size="13" /> ກັບຄືນ</button>
        </div>
      </div>
    </div>

    <!-- Stats cards -->
    <div style="display:grid; grid-template-columns:repeat(3,1fr); gap:12px; margin-bottom:16px;">
      <div class="kpi-card">
        <div style="font-size:11px; color:var(--text-muted);">ຄຳສັ່ງຊື້ທັງໝົດ</div>
        <div class="num" style="font-size:22px; font-weight:700;">{{ formatNumber(stats?.total_orders) }}</div>
      </div>
      <div class="kpi-card">
        <div style="font-size:11px; color:var(--text-muted);">ຍອດຊື້ທັງໝົດ</div>
        <div class="num" style="font-size:22px; font-weight:700;">{{ formatCompact(stats?.total_spent) }}</div>
      </div>
      <div class="kpi-card">
        <div style="font-size:11px; color:var(--text-muted);">ສິນເຊື່ອຄົງເຫຼືອ</div>
        <div class="num" style="font-size:22px; font-weight:700; color:var(--success);">{{ formatCompact(stats?.credit_available) }}</div>
      </div>
    </div>

    <!-- Tabs -->
    <div class="tab-nav">
      <button v-for="tab in tabs" :key="tab.key" class="tab-btn" :class="activeTab === tab.key && 'active'" @click="activeTab = tab.key">{{ tab.label }}</button>
    </div>

    <!-- Tab: Info -->
    <div v-if="activeTab === 'info'" class="card">
      <div class="form-row">
        <div>
          <div class="input-label">ຊື່ຮ້ານ</div>
          <div style="color:var(--text);">{{ shop.name }}</div>
        </div>
        <div>
          <div class="input-label">ເຈົ້າຂອງ</div>
          <div style="color:var(--text);">{{ shop.owner_name }}</div>
        </div>
        <div>
          <div class="input-label">ເບີໂທ</div>
          <div style="color:var(--text);" class="num">{{ shop.phone }}</div>
        </div>
        <div>
          <div class="input-label">ອີເມລ</div>
          <div style="color:var(--text);">{{ shop.email || '-' }}</div>
        </div>
        <div>
          <div class="input-label">ແຂວງ</div>
          <div style="color:var(--text);">{{ shop.province }}</div>
        </div>
        <div>
          <div class="input-label">ເມືອງ / ບ້ານ</div>
          <div style="color:var(--text);">{{ shop.district }} / {{ shop.village }}</div>
        </div>
        <div>
          <div class="input-label">ປະສົບການ</div>
          <div style="color:var(--text);">{{ shop.years_in_biz || '-' }} ປີ</div>
        </div>
        <div>
          <div class="input-label">ລາຍໄດ້ຕໍ່ເດືອນ</div>
          <div style="color:var(--text);">{{ shop.revenue_range || '-' }} ກີບ</div>
        </div>
      </div>
    </div>

    <!-- Tab: Orders -->
    <div v-if="activeTab === 'orders'">
      <div class="card" style="padding:0; overflow:hidden;">
        <div class="table-wrapper">
          <table class="table">
            <thead><tr><th>Order ID</th><th>ຈຳນວນ</th><th>ສະຖານະ</th><th>ວິທີຈ່າຍ</th><th>ວັນທີ</th></tr></thead>
            <tbody>
              <tr v-if="ordersLoading"><td colspan="5"><div class="skeleton" style="height:40px;"></div></td></tr>
              <tr v-for="o in shopOrders" :key="o.id" @click="router.push(`/orders/${o.id}`)">
                <td class="num" style="color:var(--primary);">{{ o.order_id }}</td>
                <td class="num">{{ formatCurrency(o.amount) }}</td>
                <td><span :class="statusClass(o.status)">{{ statusLabel(o.status) }}</span></td>
                <td>{{ o.payment_method }}</td>
                <td>{{ formatDate(o.created_at) }}</td>
              </tr>
              <tr v-if="!ordersLoading && !shopOrders.length"><td colspan="5"><div class="empty-state"><div>ຍັງບໍ່ມີຄຳສັ່ງຊື້</div></div></td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Tab: Payments -->
    <div v-if="activeTab === 'payments'">
      <div class="card" style="padding:0; overflow:hidden;">
        <div class="table-wrapper">
          <table class="table">
            <thead><tr><th>ID</th><th>ປະເພດ</th><th>ຈຳນວນ</th><th>ໝາຍເຫດ</th><th>ວັນທີ</th></tr></thead>
            <tbody>
              <tr v-if="paymentsLoading"><td colspan="5"><div class="skeleton" style="height:40px;"></div></td></tr>
              <tr v-for="p in shopPayments" :key="p.id">
                <td class="num" style="font-size:11px;">{{ p.id }}</td>
                <td><span class="badge badge-muted">{{ p.type }}</span></td>
                <td class="num" :style="`color:${p.type === 'payment' ? 'var(--success)' : 'var(--danger)'}`">{{ p.type === 'payment' ? '+' : '-' }}{{ formatCurrency(p.amount) }}</td>
                <td>{{ p.description || '-' }}</td>
                <td>{{ formatDate(p.created_at) }}</td>
              </tr>
              <tr v-if="!paymentsLoading && !shopPayments.length"><td colspan="5"><div class="empty-state"><div>ຍັງບໍ່ມີການຈ່າຍ</div></div></td></tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <!-- Suspend Modal -->
  <div v-if="showSuspendModal" class="modal-overlay" @click.self="showSuspendModal = false">
    <div class="modal">
      <h3 style="font-size:15px; font-weight:700; margin-bottom:12px; color:var(--danger);">Suspend ຮ້ານ?</h3>
      <p style="font-size:13px; color:var(--text-secondary); margin-bottom:20px;">ຮ້ານ "{{ shop?.name }}" ຈະຖືກ suspend ແລະ ບໍ່ສາມາດໃຊ້ສິນເຊື່ອໄດ້</p>
      <div style="display:flex; gap:10px; justify-content:flex-end;">
        <button class="btn btn-ghost" @click="showSuspendModal = false">ຍົກເລີກ</button>
        <button class="btn btn-danger" @click="handleSuspend">ຢືນຢັນ Suspend</button>
      </div>
    </div>
  </div>

  <!-- Credit Limit Modal -->
  <div v-if="showCreditModal" class="modal-overlay" @click.self="showCreditModal = false">
    <div class="modal">
      <h3 style="font-size:15px; font-weight:700; margin-bottom:16px;">ແກ້ໄຂວົງເງິນສິນເຊື່ອ</h3>
      <div class="form-group">
        <label class="input-label">ວົງເງິນໃໝ່ (ກີບ)</label>
        <input v-model.number="newLimit" type="number" class="input" />
      </div>
      <div class="form-group">
        <label class="input-label">ເຫດຜົນ</label>
        <input v-model="limitReason" type="text" class="input" placeholder="ລາຍລະອຽດ..." />
      </div>
      <div style="display:flex; gap:10px; justify-content:flex-end;">
        <button class="btn btn-ghost" @click="showCreditModal = false">ຍົກເລີກ</button>
        <button class="btn btn-primary" @click="handleCreditUpdate">ບັນທຶກ</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { CreditCard, ArrowLeft } from 'lucide-vue-next'
import { shopsApi } from '@/api/index.js'
import { useToastStore } from '@/stores/toast.js'
import { formatCurrency, formatCompact, formatNumber, formatDate, statusLabel, statusClass, tierLabel, tierClass } from '@/utils/format.js'

const route = useRoute()
const router = useRouter()
const toast = useToastStore()

const shop = ref(null)
const stats = ref(null)
const loading = ref(true)
const shopOrders = ref([])
const shopPayments = ref([])
const ordersLoading = ref(false)
const paymentsLoading = ref(false)
const activeTab = ref('info')
const showSuspendModal = ref(false)
const showCreditModal = ref(false)
const newLimit = ref(0)
const limitReason = ref('')

const tabs = [
  { key: 'info', label: 'ຂໍ້ມູນທົ່ວໄປ' },
  { key: 'orders', label: 'ຄຳສັ່ງຊື້' },
  { key: 'payments', label: 'ການຈ່າຍ' },
]

async function loadShop() {
  loading.value = true
  try {
    const [shopRes, statsRes] = await Promise.all([shopsApi.get(route.params.id), shopsApi.stats(route.params.id)])
    shop.value = shopRes.data
    stats.value = statsRes.data
    newLimit.value = shop.value.credit_limit
  } catch { router.push('/shops') }
  finally { loading.value = false }
}

async function loadOrders() {
  ordersLoading.value = true
  const { data } = await shopsApi.orders(route.params.id)
  shopOrders.value = data.items || []
  ordersLoading.value = false
}

async function loadPayments() {
  paymentsLoading.value = true
  const { data } = await shopsApi.payments(route.params.id)
  shopPayments.value = data.items || []
  paymentsLoading.value = false
}

watch(activeTab, (tab) => {
  if (tab === 'orders' && !shopOrders.value.length) loadOrders()
  if (tab === 'payments' && !shopPayments.value.length) loadPayments()
})

async function handleSuspend() {
  await shopsApi.suspend(route.params.id)
  shop.value.status = 'suspended'
  showSuspendModal.value = false
  toast.success('ໄດ້ Suspend ຮ້ານແລ້ວ')
}

async function handleActivate() {
  await shopsApi.activate(route.params.id)
  shop.value.status = 'active'
  toast.success('ໄດ້ເປີດໃຊ້ງານຮ້ານແລ້ວ')
}

async function handleCreditUpdate() {
  await shopsApi.updateCreditLimit(route.params.id, { new_limit: newLimit.value, reason: limitReason.value })
  shop.value.credit_limit = newLimit.value
  showCreditModal.value = false
  toast.success('ອັບເດດວົງເງິນສຳເລັດ')
}

onMounted(loadShop)
</script>
