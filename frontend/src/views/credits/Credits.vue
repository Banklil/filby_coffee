<template>
  <div>
    <div style="margin-bottom:24px;">
      <h1 style=" font-size:20px; font-weight:700; color:var(--cream);">ສິນເຊື່ອ & ການຊຳລະ</h1>
    </div>

    <!-- Overview KPIs -->
    <div style="display:grid; grid-template-columns:repeat(3,1fr); gap:16px; margin-bottom:24px;">
      <div class="kpi-card" v-if="overviewLoading">
        <div class="skeleton" style="height:60px;"></div>
      </div>
      <template v-else>
        <div class="kpi-card">
          <div style="font-size:11px; color:var(--text-muted);">ສິນເຊື່ອທີ່ໃຊ້ຢູ່ທັງໝົດ</div>
          <div class="num" style="font-size:22px; font-weight:700; color:var(--primary);">{{ formatCompact(overview?.total_active_credit) }} ກີບ</div>
        </div>
        <div class="kpi-card">
          <div style="font-size:11px; color:var(--text-muted);">ໃກ້ຄົບກຳນົດ (7 ວັນ)</div>
          <div class="num" style="font-size:22px; font-weight:700; color:var(--warning);">{{ overview?.due_soon_count }} ຮ້ານ</div>
        </div>
        <div class="kpi-card">
          <div style="font-size:11px; color:var(--text-muted);">ເກີນກຳນົດ</div>
          <div class="num" style="font-size:22px; font-weight:700; color:var(--danger);">{{ overview?.overdue_count }} ຮ້ານ</div>
        </div>
      </template>
    </div>

    <div style="display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-bottom:24px;">
      <!-- Due Soon -->
      <div class="card">
        <div class="card-header">
          <span style="font-size:14px; font-weight:600; color:var(--text);">ໃກ້ຄົບກຳນົດ</span>
          <span class="badge badge-warning">{{ dueSoon.length }}</span>
        </div>
        <div style="display:flex; flex-direction:column; gap:8px; max-height:320px; overflow-y:auto;">
          <div v-if="dueSoonLoading" v-for="i in 3" :key="i" class="skeleton" style="height:56px; border-radius:8px;"></div>
          <div v-for="item in dueSoon" :key="item.order_id" style="display:flex; align-items:center; gap:12px; padding:10px; background:var(--surface-2); border-radius:8px;">
            <div style="flex:1;">
              <div style="font-size:13px; font-weight:500; color:var(--text);">{{ item.shop_name }}</div>
              <div class="num" style="font-size:11px; color:var(--text-muted);">{{ item.order_id }} — {{ formatCurrency(item.amount) }}</div>
              <div class="num" style="font-size:11px; color:var(--warning);">ຄົບ {{ formatDate(item.due_date) }}</div>
            </div>
            <button class="btn btn-sm btn-ghost" style="font-size:11px;" @click="openPayment(item)">ບັນທຶກຈ່າຍ</button>
          </div>
          <div v-if="!dueSoonLoading && !dueSoon.length" class="empty-state" style="padding:20px;">
            <div>ບໍ່ມີຮ້ານໃກ້ຄົບກຳນົດ</div>
          </div>
        </div>
      </div>

      <!-- Overdue -->
      <div class="card">
        <div class="card-header">
          <span style="font-size:14px; font-weight:600; color:var(--text);">ເກີນກຳນົດ</span>
          <span class="badge badge-danger">{{ overdue.length }}</span>
        </div>
        <div style="display:flex; flex-direction:column; gap:8px; max-height:320px; overflow-y:auto;">
          <div v-if="overdueLoading" v-for="i in 3" :key="i" class="skeleton" style="height:56px; border-radius:8px;"></div>
          <div v-for="item in overdue" :key="item.order_id" style="display:flex; align-items:center; gap:12px; padding:10px; background:rgba(248,113,113,0.06); border:1px solid rgba(248,113,113,0.15); border-radius:8px;">
            <div style="flex:1;">
              <div style="font-size:13px; font-weight:500; color:var(--text);">{{ item.shop_name }}</div>
              <div class="num" style="font-size:11px; color:var(--danger);">{{ item.order_id }} — {{ formatCurrency(item.amount) }}</div>
              <div style="font-size:11px; color:var(--text-muted);">ເກີນ {{ item.days_overdue }} ວັນ | ດອກ {{ formatCurrency(item.interest) }}</div>
            </div>
            <div style="display:flex; flex-direction:column; gap:4px;">
              <a :href="`tel:${item.phone}`" class="btn btn-sm btn-ghost" style="font-size:11px;">📞 ໂທ</a>
              <button class="btn btn-sm btn-ghost" style="font-size:11px;" @click="openPayment(item)">ບັນທຶກ</button>
            </div>
          </div>
          <div v-if="!overdueLoading && !overdue.length" class="empty-state" style="padding:20px;">
            <div>ບໍ່ມີຮ້ານເກີນກຳນົດ</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Record Payment -->
    <div class="card">
      <div class="card-header">
        <span style="font-size:14px; font-weight:600; color:var(--text);">ບັນທຶກການຊຳລະ</span>
      </div>
      <div style="display:grid; grid-template-columns:1fr 1fr auto auto; gap:12px; align-items:end;">
        <div>
          <label class="input-label">Shop ID</label>
          <input v-model.number="payShopId" type="number" class="input" placeholder="Shop ID..." />
        </div>
        <div>
          <label class="input-label">ຈຳນວນ (ກີບ)</label>
          <input v-model.number="payAmount" type="number" class="input" placeholder="ຈຳນວນ..." />
        </div>
        <div>
          <label class="input-label">ໝາຍເຫດ</label>
          <input v-model="payNotes" class="input" placeholder="ໝາຍເຫດ..." />
        </div>
        <div style="padding-top:20px;">
          <button class="btn btn-primary" @click="recordPayment" :disabled="payLoading">
            {{ payLoading ? 'ກຳລັງບັນທຶກ...' : 'ບັນທຶກ' }}
          </button>
        </div>
      </div>
    </div>
  </div>

  <!-- Quick payment modal -->
  <div v-if="showPayModal" class="modal-overlay" @click.self="showPayModal = false">
    <div class="modal">
      <h3 style="font-size:15px; font-weight:700; margin-bottom:16px;">ບັນທຶກການຊຳລະ</h3>
      <div class="form-group">
        <label class="input-label">ຮ້ານ</label>
        <div style="font-weight:600; color:var(--text);">{{ selectedItem?.shop_name }}</div>
      </div>
      <div class="form-group">
        <label class="input-label">ຈຳນວນ (ກີບ)</label>
        <input v-model.number="modalAmount" type="number" class="input" />
      </div>
      <div style="display:flex; gap:10px; justify-content:flex-end;">
        <button class="btn btn-ghost" @click="showPayModal = false">ຍົກເລີກ</button>
        <button class="btn btn-primary" @click="handleModalPay">ບັນທຶກ</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { creditsApi } from '@/api/index.js'
import { useToastStore } from '@/stores/toast.js'
import { formatCurrency, formatCompact, formatDate } from '@/utils/format.js'

const toast = useToastStore()
const overview = ref(null)
const overviewLoading = ref(true)
const dueSoon = ref([])
const dueSoonLoading = ref(true)
const overdue = ref([])
const overdueLoading = ref(true)
const payShopId = ref('')
const payAmount = ref('')
const payNotes = ref('')
const payLoading = ref(false)
const showPayModal = ref(false)
const selectedItem = ref(null)
const modalAmount = ref(0)

async function loadAll() {
  const [ov, ds, od] = await Promise.all([creditsApi.overview(), creditsApi.dueSoon(), creditsApi.overdue()])
  overview.value = ov.data; overviewLoading.value = false
  dueSoon.value = ds.data; dueSoonLoading.value = false
  overdue.value = od.data; overdueLoading.value = false
}

async function recordPayment() {
  if (!payShopId.value || !payAmount.value) return toast.error('ກະລຸນາໃສ່ Shop ID ແລະ ຈຳນວນ')
  payLoading.value = true
  try {
    await creditsApi.recordPayment({ shop_id: payShopId.value, amount: payAmount.value, notes: payNotes.value })
    toast.success('ບັນທຶກການຊຳລະສຳເລັດ')
    payShopId.value = ''; payAmount.value = ''; payNotes.value = ''
    loadAll()
  } catch (e) { toast.error(e.response?.data?.detail || 'ເກີດຂໍ້ຜິດພາດ') }
  finally { payLoading.value = false }
}

function openPayment(item) {
  selectedItem.value = item
  modalAmount.value = item.amount || 0
  showPayModal.value = true
}

async function handleModalPay() {
  await creditsApi.recordPayment({ shop_id: selectedItem.value.shop_id || 1, amount: modalAmount.value })
  showPayModal.value = false
  toast.success('ບັນທຶກການຊຳລະສຳເລັດ')
  loadAll()
}

onMounted(loadAll)
</script>
