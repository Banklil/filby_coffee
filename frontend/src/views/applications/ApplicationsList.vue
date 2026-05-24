<template>
  <div>
    <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:24px;">
      <div>
        <h1 style=" font-size:20px; font-weight:700; color:var(--cream);">ຄຳສະໝັກສິນເຊື່ອ</h1>
        <p style="font-size:13px; color:var(--text-muted);">ທັງໝົດ {{ total }} ຄຳສະໝັກ</p>
      </div>
    </div>

    <!-- Status tabs -->
    <div class="tab-nav" style="margin-bottom:0;">
      <button v-for="tab in statusTabs" :key="tab.key" class="tab-btn" :class="activeStatus === tab.key && 'active'" @click="changeStatus(tab.key)">
        {{ tab.label }}
        <span v-if="tab.key === 'pending' && pendingCount" style="margin-left:4px; background:rgba(251,191,36,0.2); color:var(--warning); font-size:10px; padding:1px 5px; border-radius:10px;">{{ pendingCount }}</span>
      </button>
    </div>

    <div class="card" style="padding:0; overflow:hidden; border-top-left-radius:0;">
      <div class="table-wrapper">
        <table class="table">
          <thead>
            <tr>
              <th>Ref ID</th>
              <th>ຊື່ຮ້ານ</th>
              <th>ຈຳນວນສະໝັກ</th>
              <th>ຈຸດປະສົງ</th>
              <th>ສະຖານະ</th>
              <th>ວັນສະໝັກ</th>
              <th>ການດຳເນີນການ</th>
            </tr>
          </thead>
          <tbody>
            <template v-if="loading">
              <tr v-for="i in 5" :key="i"><td colspan="7"><div class="skeleton" style="height:20px;"></div></td></tr>
            </template>
            <template v-else-if="applications.length">
              <tr v-for="app in applications" :key="app.id" @click="router.push(`/applications/${app.id}`)">
                <td class="num" style="color:var(--primary); font-size:12px;">{{ app.ref_id }}</td>
                <td style="color:var(--text); font-weight:500;">{{ app.shop_data?.shopName || '-' }}</td>
                <td class="num">{{ formatCurrency(app.credit_requested) }}</td>
                <td><span class="badge badge-muted">{{ purposeLabel(app.purpose) }}</span></td>
                <td><span :class="statusClass(app.status)">{{ statusLabel(app.status) }}</span></td>
                <td style="font-size:12px;">{{ formatDate(app.created_at) }}</td>
                <td @click.stop>
                  <div v-if="app.status === 'pending'" style="display:flex; gap:6px;">
                    <button class="btn btn-sm" style="background:rgba(110,231,167,0.15); color:var(--success); border:none; font-size:11px;" @click.stop="openApprove(app)">Approve</button>
                    <button class="btn btn-sm btn-danger" style="font-size:11px;" @click.stop="openReject(app)">ປະຕິເສດ</button>
                  </div>
                  <span v-else style="font-size:12px; color:var(--text-muted);">-</span>
                </td>
              </tr>
            </template>
            <tr v-else>
              <td colspan="7">
                <div class="empty-state">
                  <div class="empty-icon"><FileText :size="24" color="var(--text-muted)" /></div>
                  <div style="font-weight:600; color:var(--text-secondary);">ບໍ່ມີຄຳສະໝັກ</div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div style="display:flex; align-items:center; justify-content:space-between; padding:14px 20px; border-top:1px solid var(--border);">
        <span style="font-size:12px; color:var(--text-muted);">ສະແດງ {{ applications.length }} ຈາກ {{ total }}</span>
        <div class="pagination">
          <button class="page-btn" :disabled="page <= 1" @click="load(page - 1)"><ChevronLeft :size="14" /></button>
          <button v-for="p in visiblePages" :key="p" class="page-btn" :class="p === page && 'active'" @click="load(p)">{{ p }}</button>
          <button class="page-btn" :disabled="page >= totalPages" @click="load(page + 1)"><ChevronRight :size="14" /></button>
        </div>
      </div>
    </div>
  </div>

  <!-- Approve Modal -->
  <div v-if="showApproveModal" class="modal-overlay" @click.self="showApproveModal = false">
    <div class="modal">
      <h3 style="font-size:15px; font-weight:700; margin-bottom:4px; color:var(--success);">ອະນຸມັດຄຳສະໝັກ</h3>
      <p style="font-size:12px; color:var(--text-muted); margin-bottom:16px;">{{ selectedApp?.shop_data?.shopName }} — ສະໝັກ {{ formatCurrency(selectedApp?.credit_requested) }}</p>
      <div class="form-group">
        <label class="input-label">ວົງເງິນທີ່ອະນຸມັດ (ກີບ)</label>
        <input v-model.number="approveLimit" type="number" class="input" />
      </div>
      <div class="form-group">
        <label class="input-label">ໝາຍເຫດ</label>
        <input v-model="approveNotes" class="input" placeholder="ໝາຍເຫດ (ບໍ່ບັງຄັບ)..." />
      </div>
      <div style="display:flex; gap:10px; justify-content:flex-end;">
        <button class="btn btn-ghost" @click="showApproveModal = false">ຍົກເລີກ</button>
        <button class="btn btn-primary" @click="handleApprove" :disabled="actionLoading">{{ actionLoading ? 'ກຳລັງດຳເນີນ...' : 'ຢືນຢັນ Approve' }}</button>
      </div>
    </div>
  </div>

  <!-- Reject Modal -->
  <div v-if="showRejectModal" class="modal-overlay" @click.self="showRejectModal = false">
    <div class="modal">
      <h3 style="font-size:15px; font-weight:700; margin-bottom:4px; color:var(--danger);">ປະຕິເສດຄຳສະໝັກ</h3>
      <p style="font-size:12px; color:var(--text-muted); margin-bottom:16px;">{{ selectedApp?.shop_data?.shopName }}</p>
      <div class="form-group">
        <label class="input-label">ເຫດຜົນ</label>
        <input v-model="rejectReason" class="input" placeholder="ເຫດຜົນໃນການປະຕິເສດ..." required />
      </div>
      <div style="display:flex; gap:10px; justify-content:flex-end;">
        <button class="btn btn-ghost" @click="showRejectModal = false">ຍົກເລີກ</button>
        <button class="btn btn-danger" @click="handleReject" :disabled="actionLoading">{{ actionLoading ? 'ກຳລັງດຳເນີນ...' : 'ຢືນຢັນ ປະຕິເສດ' }}</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { FileText, ChevronLeft, ChevronRight } from 'lucide-vue-next'
import { applicationsApi } from '@/api/index.js'
import { useToastStore } from '@/stores/toast.js'
import { formatCurrency, formatDate, statusLabel, statusClass } from '@/utils/format.js'

const router = useRouter()
const toast = useToastStore()

const applications = ref([])
const total = ref(0)
const totalPages = ref(1)
const page = ref(1)
const loading = ref(true)
const activeStatus = ref('pending')
const pendingCount = ref(0)

const showApproveModal = ref(false)
const showRejectModal = ref(false)
const selectedApp = ref(null)
const approveLimit = ref(0)
const approveNotes = ref('')
const rejectReason = ref('')
const actionLoading = ref(false)

const statusTabs = [
  { key: 'pending', label: 'ລໍຖ້າ Review' },
  { key: 'approved', label: 'ອະນຸມັດ' },
  { key: 'rejected', label: 'ປະຕິເສດ' },
  { key: 'all', label: 'ທັງໝົດ' },
]

const visiblePages = computed(() => {
  const pages = []
  const start = Math.max(1, page.value - 2)
  for (let i = start; i <= Math.min(totalPages.value, start + 4); i++) pages.push(i)
  return pages
})

function purposeLabel(p) {
  return { beans: 'ເມັດກາເຟ', equipment: 'ອຸປະກອນ', expansion: 'ຂະຫຍາຍ' }[p] || p || '-'
}

async function load(p = 1) {
  loading.value = true
  page.value = p
  const { data } = await applicationsApi.list({ status: activeStatus.value, page: p, limit: 20 })
  applications.value = data.items
  total.value = data.total
  totalPages.value = data.pages
  loading.value = false
}

async function loadPendingCount() {
  const { data } = await applicationsApi.list({ status: 'pending', page: 1, limit: 1 })
  pendingCount.value = data.total
}

function changeStatus(s) {
  activeStatus.value = s
  load(1)
}

function openApprove(app) {
  selectedApp.value = app
  approveLimit.value = app.credit_requested
  approveNotes.value = ''
  showApproveModal.value = true
}

function openReject(app) {
  selectedApp.value = app
  rejectReason.value = ''
  showRejectModal.value = true
}

async function handleApprove() {
  actionLoading.value = true
  try {
    await applicationsApi.approve(selectedApp.value.id, { approved_limit: approveLimit.value, notes: approveNotes.value })
    showApproveModal.value = false
    toast.success('ອະນຸມັດຄຳສະໝັກສຳເລັດ')
    load(page.value)
    loadPendingCount()
  } catch (e) { toast.error(e.response?.data?.detail || 'ເກີດຂໍ້ຜິດພາດ') }
  finally { actionLoading.value = false }
}

async function handleReject() {
  if (!rejectReason.value) return toast.error('ກະລຸນາໃສ່ເຫດຜົນ')
  actionLoading.value = true
  try {
    await applicationsApi.reject(selectedApp.value.id, { reason: rejectReason.value })
    showRejectModal.value = false
    toast.success('ປະຕິເສດຄຳສະໝັກແລ້ວ')
    load(page.value)
    loadPendingCount()
  } catch (e) { toast.error(e.response?.data?.detail || 'ເກີດຂໍ້ຜິດພາດ') }
  finally { actionLoading.value = false }
}

onMounted(() => { load(); loadPendingCount() })
</script>
