<template>
  <div>
    <div style="margin-bottom:24px;">
      <h1 style=" font-size:20px; font-weight:700; color:var(--cream);">ລາຍງານ</h1>
      <p style="font-size:13px; color:var(--text-muted);">Download ລາຍງານ ແລະ ຂໍ້ມູນ</p>
    </div>

    <div style="display:grid; grid-template-columns:repeat(2, 1fr); gap:16px;">
      <div class="card" v-for="report in reports" :key="report.key">
        <div style="display:flex; align-items:flex-start; gap:14px;">
          <div :style="`background:${report.iconBg}; border-radius:10px; padding:12px; display:flex;`">
            <component :is="report.icon" :size="18" :color="report.iconColor" />
          </div>
          <div style="flex:1;">
            <div style="font-size:14px; font-weight:600; color:var(--text); margin-bottom:4px;">{{ report.title }}</div>
            <div style="font-size:12px; color:var(--text-muted); margin-bottom:12px;">{{ report.desc }}</div>
            <button class="btn btn-ghost btn-sm" @click="downloadReport(report)" :disabled="downloading === report.key">
              <Loader2 v-if="downloading === report.key" :size="13" class="spin" />
              <Download v-else :size="13" />
              {{ downloading === report.key ? 'ກຳລັງ Download...' : 'Download' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Shop Statement -->
      <div class="card">
        <div style="display:flex; align-items:flex-start; gap:14px;">
          <div style="background:rgba(232,133,74,0.12); border-radius:10px; padding:12px; display:flex;">
            <FileText :size="18" color="var(--primary)" />
          </div>
          <div style="flex:1;">
            <div style="font-size:14px; font-weight:600; color:var(--text); margin-bottom:4px;">Statement ຮ້ານ</div>
            <div style="font-size:12px; color:var(--text-muted); margin-bottom:12px;">ລາຍງານປະຈຳເດືອນຂອງຮ້ານ</div>
            <div style="display:flex; gap:8px; flex-wrap:wrap;">
              <input v-model.number="shopIdInput" type="number" class="input" placeholder="Shop ID" style="width:100px;" />
              <input v-model="monthInput" type="month" class="input" style="width:140px;" />
              <button class="btn btn-ghost btn-sm" @click="downloadStatement" :disabled="downloading === 'statement'">
                <Download :size="13" /> Download PDF
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { FileSpreadsheet, CreditCard, FileText, Download, Loader2 } from 'lucide-vue-next'
import { reportsApi } from '@/api/index.js'
import { useToastStore } from '@/stores/toast.js'

const toast = useToastStore()
const downloading = ref(null)
const shopIdInput = ref('')
const monthInput = ref(new Date().toISOString().substring(0, 7))

const reports = [
  {
    key: 'orders',
    title: 'ຄຳສັ່ງຊື້ທັງໝົດ',
    desc: 'Export ທຸກ orders ເປັນ Excel',
    icon: FileSpreadsheet,
    iconBg: 'rgba(110,231,167,0.1)',
    iconColor: 'var(--success)',
  },
  {
    key: 'payments',
    title: 'ການຊຳລະທັງໝົດ',
    desc: 'Export ທຸກ transactions ເປັນ Excel',
    icon: CreditCard,
    iconBg: 'rgba(232,133,74,0.1)',
    iconColor: 'var(--primary)',
  },
]

function saveBlobAs(blob, filename) {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url; a.download = filename; a.click()
  URL.revokeObjectURL(url)
}

async function downloadReport(report) {
  downloading.value = report.key
  try {
    const { data } = report.key === 'orders' ? await reportsApi.exportOrders() : await reportsApi.exportPayments()
    saveBlobAs(data, `filby-${report.key}-${new Date().toISOString().slice(0,10)}.xlsx`)
    toast.success('Download ສຳເລັດ')
  } catch { toast.error('ດາວໂຫຼດບໍ່ສຳເລັດ') }
  finally { downloading.value = null }
}

async function downloadStatement() {
  if (!shopIdInput.value || !monthInput.value) return toast.error('ກະລຸນາໃສ່ Shop ID ແລະ ເດືອນ')
  downloading.value = 'statement'
  try {
    const { data } = await reportsApi.shopStatement(shopIdInput.value, monthInput.value)
    saveBlobAs(data, `statement-${shopIdInput.value}-${monthInput.value}.pdf`)
    toast.success('Download ສຳເລັດ')
  } catch { toast.error('ດາວໂຫຼດບໍ່ສຳເລັດ') }
  finally { downloading.value = null }
}
</script>

<style scoped>
.spin { animation: spin 1s linear infinite; }
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
</style>
