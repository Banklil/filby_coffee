<template>
  <div>
    <div style="margin-bottom:24px;">
      <h1 style="font-size:20px; font-weight:700; color:var(--cream);">ການຊຳລະ QR</h1>
      <div style="font-size:13px; color:var(--text-muted); margin-top:4px;">ອັບໂຫລດ QR ບໍລິສັດ ແລະ ຢືນຢັນການຊຳລະ</div>
    </div>

    <!-- Tabs -->
    <div class="tab-nav" style="margin-bottom:24px;">
      <button class="tab-btn" :class="tab === 'qr' && 'active'" @click="tab = 'qr'">
        📲 QR Code
      </button>
      <button class="tab-btn" :class="tab === 'pending' && 'active'" @click="switchPending">
        ⏳ ລໍຖ້າຢືນຢັນ
        <span v-if="pending.length > 0" style="margin-left:6px; background:var(--danger); color:#fff; font-size:10px; font-weight:700; padding:1px 6px; border-radius:10px;">{{ pending.length }}</span>
      </button>
    </div>

    <!-- ── Tab: QR Code ── -->
    <div v-if="tab === 'qr'" style="max-width:680px;">

      <!-- Current QR card -->
      <div class="card" style="margin-bottom:16px; padding:24px;">
        <div style="font-size:11px; font-weight:600; color:var(--text-muted); text-transform:uppercase; letter-spacing:0.08em; margin-bottom:16px;">QR Code ປັດຈຸບັນ</div>

        <div v-if="qrUrl" style="display:flex; align-items:flex-start; gap:24px; flex-wrap:wrap;">
          <div style="background:#fff; border-radius:12px; padding:12px; box-shadow:0 2px 12px rgba(0,0,0,0.3);">
            <img :src="qrUrl" alt="QR" style="width:180px; height:180px; object-fit:contain; display:block;" />
          </div>
          <div style="padding-top:8px;">
            <div style="color: var(--success, #4caf50); font-size:13px; font-weight:600; margin-bottom:12px; display:flex; align-items:center; gap:6px;">
              <CheckCircle :size="15" /> ໃຊ້ງານໄດ້ — ລູກຄ້າຈະເຫັນ QR ນີ້
            </div>
            <div style="font-size:11px; color:var(--text-muted); word-break:break-all; max-width:280px; margin-bottom:12px;">{{ qrUrl }}</div>
            <button class="btn btn-danger btn-sm" @click="deleteQr">
              <Trash2 :size="12" /> ລຶບ QR
            </button>
          </div>
        </div>

        <div v-else style="display:flex; align-items:center; gap:16px; color:var(--text-muted);">
          <QrCode :size="48" style="opacity:0.3;" />
          <div>
            <div style="font-size:14px; font-weight:500; color:var(--text-secondary); margin-bottom:4px;">ຍັງບໍ່ມີ QR code</div>
            <div style="font-size:12px;">ອັບໂຫລດຮູບ QR ດ້ານລຸ່ມ</div>
          </div>
        </div>
      </div>

      <!-- Upload card -->
      <div class="card" style="margin-bottom:16px; padding:24px;">
        <div style="font-size:11px; font-weight:600; color:var(--text-muted); text-transform:uppercase; letter-spacing:0.08em; margin-bottom:16px;">
          {{ qrUrl ? 'ແທນທີ່ QR Code' : 'ອັບໂຫລດ QR Code' }}
        </div>

        <div
          @dragover.prevent="dragOver = true"
          @dragleave="dragOver = false"
          @drop.prevent="onDrop"
          @click="fileInput?.click()"
          :style="{
            border: `2px dashed ${dragOver ? 'var(--primary)' : 'var(--border)'}`,
            background: dragOver ? 'rgba(232,133,74,0.05)' : '',
            borderRadius: '10px',
            padding: '40px 20px',
            textAlign: 'center',
            cursor: 'pointer',
            transition: 'all 0.15s',
          }"
        >
          <div v-if="uploading">
            <div class="spinner" style="margin:0 auto 12px; width:32px; height:32px;"></div>
            <div style="font-size:13px; color:var(--text-muted);">ກຳລັງອັບໂຫລດ...</div>
          </div>
          <div v-else>
            <Upload :size="36" style="color:var(--text-muted); opacity:0.5; margin-bottom:12px;" />
            <div style="font-size:13px; font-weight:500; color:var(--text-secondary); margin-bottom:4px;">ລາກຮູບໃສ່ ຫຼື ກົດເພື່ອເລືອກ</div>
            <div style="font-size:11px; color:var(--text-muted);">PNG, JPG · ສູງສຸດ 5 MB</div>
          </div>
        </div>
        <input ref="fileInput" type="file" accept="image/png,image/jpeg" style="display:none;" @change="onFileChange" />

        <div v-if="uploadMsg" style="margin-top:12px; color:var(--success, #4caf50); font-size:13px; display:flex; align-items:center; gap:6px;">
          <CheckCircle :size="14" /> {{ uploadMsg }}
        </div>
        <div v-if="uploadErr" style="margin-top:12px; color:var(--danger); font-size:13px; display:flex; align-items:center; gap:6px;">
          <AlertCircle :size="14" /> {{ uploadErr }}
        </div>
      </div>

      <!-- Info card -->
      <div class="card" style="padding:20px; border:1px solid rgba(232,133,74,0.2); background:rgba(232,133,74,0.04);">
        <div style="font-size:12px; font-weight:600; color:var(--primary); margin-bottom:10px;">📋 ຄຳແນະນຳ</div>
        <ul style="font-size:12px; color:var(--text-secondary); line-height:1.8; padding-left:16px; margin:0;">
          <li>ອັບໂຫລດ QR code ຂອງ BCEL One, LDB ຫຼື Unitel Money ຂອງບໍລິສັດ</li>
          <li>ລູກຄ້າຈະເຫັນຮູບນີ້ໃນໜ້າຊຳລະຂອງ app ແທນ placeholder icon</li>
          <li>ຫຼັງລູກຄ້າສະແກນ ແລະ ກົດ "ຂ້ອຍສະແກນແລ້ວ" → order ຈະຂຶ້ນໃນ Tab "ລໍຖ້າຢືນຢັນ"</li>
          <li>ກວດເງີນໃນ app ທະນາຄານ ແລ້ວກົດ "ຢືນຢັນ" ເພື່ອ confirm order</li>
        </ul>
      </div>
    </div>

    <!-- ── Tab: Pending Payments ── -->
    <div v-else style="max-width:800px;">
      <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:16px;">
        <div style="font-size:13px; color:var(--text-muted);">ລາຍການທີ່ລູກຄ້າສະແກນ QR ແລ້ວ ລໍຖ້າ admin ຢືນຢັນ</div>
        <button class="btn btn-ghost btn-sm" @click="loadPending" :disabled="loadingP">
          <RefreshCw :size="13" :class="loadingP && 'spin'" /> Refresh
        </button>
      </div>

      <div v-if="confirmMsg" style="background:rgba(76,175,80,0.1); border:1px solid rgba(76,175,80,0.3); border-radius:8px; padding:10px 14px; font-size:13px; color:var(--success, #4caf50); margin-bottom:16px; display:flex; align-items:center; gap:8px;">
        <CheckCircle :size="14" /> {{ confirmMsg }}
      </div>

      <div v-if="loadingP" style="text-align:center; padding:60px 0;">
        <div class="spinner" style="margin:0 auto; width:32px; height:32px;"></div>
      </div>

      <div v-else-if="pending.length === 0" class="card" style="text-align:center; padding:60px 20px;">
        <CheckCircle :size="40" style="color:var(--text-muted); opacity:0.3; margin-bottom:12px;" />
        <div style="font-size:14px; color:var(--text-muted);">ບໍ່ມີ order ລໍຖ້າຢືນຢັນ</div>
      </div>

      <div v-else style="display:flex; flex-direction:column; gap:12px;">
        <div
          v-for="o in pending"
          :key="o.id"
          class="card"
          style="padding:20px; border:1px solid rgba(255,193,7,0.2); background:rgba(255,193,7,0.03);"
        >
          <div style="display:flex; align-items:flex-start; gap:16px;">
            <div style="flex:1; min-width:0;">
              <div style="display:flex; align-items:center; gap:8px; flex-wrap:wrap; margin-bottom:8px;">
                <span style="background:rgba(255,193,7,0.15); color:#ffc107; border:1px solid rgba(255,193,7,0.3); font-size:11px; font-weight:600; padding:2px 8px; border-radius:20px;">⏳ ລໍຖ້າ</span>
                <span style="font-size:11px; color:var(--text-muted);">{{ timeAgo(o.created_at) }}</span>
                <span style="font-size:11px; color:var(--text-muted);">#{{ o.id }}</span>
              </div>
              <div style="font-size:15px; font-weight:700; color:var(--cream); margin-bottom:4px;">{{ o.shop_name || o.owner_name }}</div>
              <div style="font-size:13px; color:var(--text-secondary); margin-bottom:2px;">{{ o.product_name }} · {{ o.quantity }} {{ o.unit }}</div>
              <div v-if="o.phone" style="font-size:12px; color:var(--text-muted);">📞 {{ o.phone }}</div>
            </div>
            <div style="text-align:right; flex-shrink:0;">
              <div style="font-size:20px; font-weight:800; color:var(--primary);">{{ fmt(o.total_price) }}</div>
              <div style="font-size:11px; color:var(--text-muted);">ກີບ</div>
            </div>
          </div>

          <div style="display:flex; gap:8px; margin-top:16px;">
            <button class="btn btn-primary btn-sm" style="flex:1; justify-content:center;" @click="confirmOrder(o.id)">
              <Check :size="14" /> ຢືນຢັນຮັບເງິນ
            </button>
            <button class="btn btn-danger btn-sm" @click="rejectOrder(o.id)">
              <X :size="14" /> ຍົກເລີກ
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { QrCode, Upload, Trash2, CheckCircle, AlertCircle, RefreshCw, Check, X } from 'lucide-vue-next'
import client from '@/api/client.js'

const tab       = ref('qr')
const fileInput = ref(null)

// ── QR ────────────────────────────────────────────────────────────
const qrUrl     = ref(null)
const uploading = ref(false)
const uploadMsg = ref('')
const uploadErr = ref('')
const dragOver  = ref(false)

async function loadQr() {
  try {
    const { data } = await client.get('/api/payment/qr')
    qrUrl.value = data.exists ? data.url : null
  } catch { qrUrl.value = null }
}

function onDrop(e) {
  dragOver.value = false
  const file = e.dataTransfer?.files?.[0]
  if (file) doUpload(file)
}
function onFileChange(e) {
  const file = e.target.files?.[0]
  if (file) doUpload(file)
}

async function doUpload(file) {
  if (!file.type.startsWith('image/')) {
    uploadErr.value = 'ຮູບຕ້ອງເປັນ PNG ຫຼື JPEG'
    return
  }
  uploadMsg.value = ''
  uploadErr.value = ''
  uploading.value = true
  try {
    const fd = new FormData()
    fd.append('file', file)
    const { data } = await client.post('/api/payment/qr', fd)
    uploadMsg.value = data.message
    await loadQr()
  } catch (e) {
    uploadErr.value = e.response?.data?.detail ?? e.message
  } finally {
    uploading.value = false
    if (fileInput.value) fileInput.value.value = ''
  }
}

async function deleteQr() {
  if (!confirm('ລຶບ QR code ນີ້ບໍ?')) return
  try {
    await client.delete('/api/payment/qr')
    qrUrl.value = null
    uploadMsg.value = 'ລຶບ QR ແລ້ວ'
  } catch (e) {
    uploadErr.value = e.response?.data?.detail ?? e.message
  }
}

// ── Pending ───────────────────────────────────────────────────────
const pending    = ref([])
const loadingP   = ref(false)
const confirmMsg = ref('')

async function loadPending() {
  loadingP.value = true
  try {
    const { data } = await client.get('/api/payment/pending')
    pending.value = data
  } catch { pending.value = [] }
  finally { loadingP.value = false }
}

async function confirmOrder(id) {
  try {
    const { data } = await client.post(`/api/payment/confirm/${id}`)
    confirmMsg.value = data.message
    pending.value = pending.value.filter(o => o.id !== id)
  } catch (e) {
    alert(e.response?.data?.detail ?? e.message)
  }
}

async function rejectOrder(id) {
  if (!confirm('ຍົກເລີກ order ນີ້ບໍ?')) return
  try {
    await client.post(`/api/payment/reject/${id}`)
    pending.value = pending.value.filter(o => o.id !== id)
  } catch (e) {
    alert(e.response?.data?.detail ?? e.message)
  }
}

function switchPending() {
  tab.value = 'pending'
  confirmMsg.value = ''
  loadPending()
}

function fmt(n) {
  return Number(n).toLocaleString()
}

function timeAgo(iso) {
  if (!iso) return ''
  const diff = Date.now() - new Date(iso).getTime()
  const m = Math.floor(diff / 60000)
  if (m < 1)  return 'ໄລ່ນີ້ໆ'
  if (m < 60) return `${m} ນາທີກ່ອນ`
  const h = Math.floor(m / 60)
  if (h < 24) return `${h} ຊ/ກ ກ່ອນ`
  return `${Math.floor(h / 24)} ວັນກ່ອນ`
}

onMounted(loadQr)
</script>

<style scoped>
.spin { animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
</style>
