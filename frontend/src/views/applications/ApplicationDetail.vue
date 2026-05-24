<template>
  <div v-if="loading">
    <div class="skeleton" style="height:100px; margin-bottom:16px;"></div>
    <div class="skeleton" style="height:400px;"></div>
  </div>
  <div v-else-if="app">
    <!-- Header -->
    <div style="display:flex; align-items:center; gap:12px; margin-bottom:20px;">
      <button class="btn btn-ghost btn-sm" @click="router.back()"><ArrowLeft :size="13" /> ກັບຄືນ</button>
      <div>
        <span class="num" style="color:var(--primary); font-size:13px; font-weight:600;">{{ app.ref_id }}</span>
        <span :class="statusClass(app.status)" style="margin-left:10px;">{{ statusLabel(app.status) }}</span>
      </div>
    </div>

    <div style="display:grid; grid-template-columns:1fr 320px; gap:16px;">
      <!-- Main info -->
      <div style="display:flex; flex-direction:column; gap:16px;">
        <div class="card">
          <div class="card-header"><span style="font-size:14px; font-weight:600; color:var(--text);">ຂໍ້ມູນຮ້ານ</span></div>
          <div class="form-row">
            <div><div class="input-label">ຊື່ຮ້ານ</div><div style="color:var(--text); font-weight:600;">{{ sd.shopName || '-' }}</div></div>
            <div><div class="input-label">ເຈົ້າຂອງ</div><div style="color:var(--text);">{{ sd.ownerName || '-' }}</div></div>
            <div><div class="input-label">ເບີໂທ</div><div style="color:var(--text);" class="num">{{ sd.phone || '-' }}</div></div>
            <div><div class="input-label">ອີເມລ</div><div style="color:var(--text);">{{ sd.email || '-' }}</div></div>
            <div><div class="input-label">ແຂວງ / ເມືອງ</div><div style="color:var(--text);">{{ sd.province }} / {{ sd.district }}</div></div>
            <div><div class="input-label">ບ້ານ</div><div style="color:var(--text);">{{ sd.village || '-' }}</div></div>
          </div>
        </div>

        <div class="card">
          <div class="card-header"><span style="font-size:14px; font-weight:600; color:var(--text);">ຂໍ້ມູນທຸລະກິດ</span></div>
          <div class="form-row">
            <div><div class="input-label">ປະສົບການ</div><div style="color:var(--text);">{{ sd.yearsInBiz || '-' }} ປີ</div></div>
            <div><div class="input-label">ລາຍໄດ້/ເດືອນ</div><div style="color:var(--text);">{{ sd.revenueRange || '-' }} ກີບ</div></div>
            <div><div class="input-label">ຈຳນວນພະນັກງານ</div><div style="color:var(--text);">{{ sd.staffCount || '-' }} ຄົນ</div></div>
            <div><div class="input-label">ປະເພດຮ້ານ</div><div style="color:var(--text);">{{ (sd.shopTypes || []).join(', ') || '-' }}</div></div>
          </div>
        </div>

        <div class="card">
          <div class="card-header"><span style="font-size:14px; font-weight:600; color:var(--text);">ສິນເຊື່ອທີ່ຮ້ອງຂໍ</span></div>
          <div style="display:flex; gap:24px;">
            <div>
              <div class="input-label">ຍອດຮ້ອງຂໍ</div>
              <div class="num" style="font-size:22px; font-weight:700; color:var(--primary);">{{ formatCurrency(app.credit_requested) }}</div>
            </div>
            <div>
              <div class="input-label">ຈຸດປະສົງ</div>
              <span class="badge badge-info">{{ purposeLabel(app.purpose) }}</span>
            </div>
            <div v-if="app.approved_limit">
              <div class="input-label">ວົງເງິນທີ່ອະນຸມັດ</div>
              <div class="num" style="font-size:22px; font-weight:700; color:var(--success);">{{ formatCurrency(app.approved_limit) }}</div>
            </div>
          </div>
          <div v-if="app.review_notes" style="margin-top:16px; padding:12px; background:var(--surface-2); border-radius:8px;">
            <div class="input-label" style="margin-bottom:4px;">ໝາຍເຫດ</div>
            <div style="font-size:13px; color:var(--text-secondary);">{{ app.review_notes }}</div>
          </div>
        </div>
      </div>

      <!-- Sidebar actions -->
      <div style="display:flex; flex-direction:column; gap:12px;">
        <div class="card">
          <div style="font-size:13px; font-weight:600; color:var(--text); margin-bottom:12px;">ການດຳເນີນການ</div>
          <template v-if="app.status === 'pending'">
            <button class="btn btn-primary" style="width:100%; justify-content:center; margin-bottom:8px;" @click="showApproveModal = true">
              <CheckCircle :size="14" /> ອະນຸມັດ
            </button>
            <button class="btn btn-danger" style="width:100%; justify-content:center; margin-bottom:8px;" @click="showRejectModal = true">
              <XCircle :size="14" /> ປະຕິເສດ
            </button>
            <button class="btn btn-ghost" style="width:100%; justify-content:center;" @click="showInfoModal = true">
              <MessageSquare :size="14" /> ຂໍຂໍ້ມູນເພີ່ມ
            </button>
          </template>
          <div v-else style="padding:12px; background:var(--surface-2); border-radius:8px; font-size:12px; color:var(--text-muted); text-align:center;">
            ຄຳສະໝັກນີ້ <span :class="statusClass(app.status)">{{ statusLabel(app.status) }}</span> ແລ້ວ
          </div>
        </div>

        <div class="card">
          <div style="font-size:12px; color:var(--text-muted); margin-bottom:8px;">ຂໍ້ມູນຄຳສະໝັກ</div>
          <div style="display:flex; flex-direction:column; gap:8px; font-size:12px;">
            <div style="display:flex; justify-content:space-between;"><span style="color:var(--text-muted);">ວັນສະໝັກ</span><span style="color:var(--text);">{{ formatDate(app.created_at) }}</span></div>
            <div v-if="app.reviewed_at" style="display:flex; justify-content:space-between;"><span style="color:var(--text-muted);">ວັນ Review</span><span style="color:var(--text);">{{ formatDate(app.reviewed_at) }}</span></div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Approve Modal -->
  <div v-if="showApproveModal" class="modal-overlay" @click.self="showApproveModal = false">
    <div class="modal">
      <h3 style="font-size:15px; font-weight:700; margin-bottom:16px; color:var(--success);">ອະນຸມັດຄຳສະໝັກ</h3>
      <div class="form-group">
        <label class="input-label">ວົງເງິນທີ່ອະນຸມັດ (ກີບ)</label>
        <input v-model.number="approveLimit" type="number" class="input" />
      </div>
      <div class="form-group">
        <label class="input-label">ໝາຍເຫດ</label>
        <input v-model="approveNotes" class="input" placeholder="ໝາຍເຫດ..." />
      </div>
      <div style="display:flex; gap:10px; justify-content:flex-end;">
        <button class="btn btn-ghost" @click="showApproveModal = false">ຍົກເລີກ</button>
        <button class="btn btn-primary" @click="handleApprove" :disabled="actionLoading">ຢືນຢັນ Approve</button>
      </div>
    </div>
  </div>

  <!-- Reject Modal -->
  <div v-if="showRejectModal" class="modal-overlay" @click.self="showRejectModal = false">
    <div class="modal">
      <h3 style="font-size:15px; font-weight:700; margin-bottom:16px; color:var(--danger);">ປະຕິເສດຄຳສະໝັກ</h3>
      <div class="form-group">
        <label class="input-label">ເຫດຜົນ</label>
        <input v-model="rejectReason" class="input" placeholder="ເຫດຜົນ..." required />
      </div>
      <div style="display:flex; gap:10px; justify-content:flex-end;">
        <button class="btn btn-ghost" @click="showRejectModal = false">ຍົກເລີກ</button>
        <button class="btn btn-danger" @click="handleReject" :disabled="actionLoading">ຢືນຢັນ ປະຕິເສດ</button>
      </div>
    </div>
  </div>

  <!-- Request Info Modal -->
  <div v-if="showInfoModal" class="modal-overlay" @click.self="showInfoModal = false">
    <div class="modal">
      <h3 style="font-size:15px; font-weight:700; margin-bottom:16px;">ຂໍຂໍ້ມູນເພີ່ມ</h3>
      <div class="form-group">
        <label class="input-label">ຂໍ້ຄວາມ</label>
        <textarea v-model="infoMessage" class="input" style="height:100px; resize:vertical;" placeholder="ຂໍ້ໃດທ່ານຕ້ອງການຂໍ້ມູນ..."></textarea>
      </div>
      <div style="display:flex; gap:10px; justify-content:flex-end;">
        <button class="btn btn-ghost" @click="showInfoModal = false">ຍົກເລີກ</button>
        <button class="btn btn-primary" @click="handleRequestInfo">ສົ່ງ</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ArrowLeft, CheckCircle, XCircle, MessageSquare } from 'lucide-vue-next'
import { applicationsApi } from '@/api/index.js'
import { useToastStore } from '@/stores/toast.js'
import { formatCurrency, formatDate, statusLabel, statusClass } from '@/utils/format.js'

const route = useRoute()
const router = useRouter()
const toast = useToastStore()

const app = ref(null)
const loading = ref(true)
const showApproveModal = ref(false)
const showRejectModal = ref(false)
const showInfoModal = ref(false)
const approveLimit = ref(0)
const approveNotes = ref('')
const rejectReason = ref('')
const infoMessage = ref('')
const actionLoading = ref(false)

const sd = computed(() => app.value?.shop_data || {})

function purposeLabel(p) {
  return { beans: 'ເມັດກາເຟ', equipment: 'ອຸປະກອນ', expansion: 'ຂະຫຍາຍທຸລະກິດ' }[p] || p || '-'
}

async function load() {
  loading.value = true
  try {
    const { data } = await applicationsApi.get(route.params.id)
    app.value = data
    approveLimit.value = data.credit_requested
  } catch { router.push('/applications') }
  finally { loading.value = false }
}

async function handleApprove() {
  actionLoading.value = true
  try {
    await applicationsApi.approve(app.value.id, { approved_limit: approveLimit.value, notes: approveNotes.value })
    app.value.status = 'approved'
    app.value.approved_limit = approveLimit.value
    showApproveModal.value = false
    toast.success('ອະນຸມັດຄຳສະໝັກສຳເລັດ — ສ້າງ Shop Account ແລ້ວ')
  } catch (e) { toast.error(e.response?.data?.detail || 'ເກີດຂໍ້ຜິດພາດ') }
  finally { actionLoading.value = false }
}

async function handleReject() {
  if (!rejectReason.value) return toast.error('ກະລຸນາໃສ່ເຫດຜົນ')
  actionLoading.value = true
  try {
    await applicationsApi.reject(app.value.id, { reason: rejectReason.value })
    app.value.status = 'rejected'
    showRejectModal.value = false
    toast.success('ປະຕິເສດຄຳສະໝັກແລ້ວ')
  } catch (e) { toast.error(e.response?.data?.detail || 'ເກີດຂໍ້ຜິດພາດ') }
  finally { actionLoading.value = false }
}

async function handleRequestInfo() {
  await applicationsApi.requestInfo(app.value.id, { message: infoMessage.value })
  showInfoModal.value = false
  toast.success('ສົ່ງຂໍ້ຄວາມສຳເລັດ')
}

onMounted(load)
</script>
