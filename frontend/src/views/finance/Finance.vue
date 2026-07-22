<template>
  <div style="display:flex; flex-direction:column; gap:16px;">

    <!-- Header -->
    <div style="display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:10px;">
      <div>
        <h1 style="font-size:20px; font-weight:700; color:var(--cream);">ການເງິນບໍລິສັດ</h1>
        <p style="color:var(--text-muted); font-size:13px; margin-top:2px;">ທຶນ · ລາຍຮັບ · ລາຍຈ່າຍ · ກຳໄລ/ຂາດທຶນ</p>
      </div>
      <button class="btn btn-primary" @click="openCreate" style="display:flex; align-items:center; gap:6px;">
        <Plus :size="14" /> ເພີ່ມລາຍການ
      </button>
    </div>

    <!-- Summary Cards -->
    <div style="display:grid; grid-template-columns:repeat(4, 1fr); gap:14px;">
      <div class="kpi-card">
        <div style="font-size:12px; color:var(--text-muted); margin-bottom:8px;">ທຶນລວມ</div>
        <div style="font-size:22px; font-weight:700; color:var(--cream);">{{ formatCompact(summary?.total_capital) }}</div>
        <div style="font-size:11px; color:var(--text-muted); margin-top:4px;">ກີບ</div>
      </div>
      <div class="kpi-card">
        <div style="font-size:12px; color:var(--text-muted); margin-bottom:8px;">ລາຍຮັບເດືອນນີ້</div>
        <div style="font-size:22px; font-weight:700; color:var(--success);">{{ formatCompact(summary?.month_income) }}</div>
        <div style="font-size:11px; color:var(--text-muted); margin-top:4px;">ກີບ</div>
      </div>
      <div class="kpi-card">
        <div style="font-size:12px; color:var(--text-muted); margin-bottom:8px;">ລາຍຈ່າຍເດືອນນີ້</div>
        <div style="font-size:22px; font-weight:700; color:var(--danger);">{{ formatCompact(summary?.month_expense) }}</div>
        <div style="font-size:11px; color:var(--text-muted); margin-top:4px;">ກີບ</div>
      </div>
      <div class="kpi-card">
        <div style="font-size:12px; color:var(--text-muted); margin-bottom:8px;">ກຳໄລ / ຂາດທຶນ</div>
        <div :style="`font-size:22px; font-weight:700; color:${(summary?.month_net||0) >= 0 ? 'var(--success)' : 'var(--danger)'}`">
          {{ (summary?.month_net || 0) >= 0 ? '+' : '' }}{{ formatCompact(summary?.month_net) }}
        </div>
        <div style="font-size:11px; color:var(--text-muted); margin-top:4px;">ກີບ ເດືອນນີ້</div>
      </div>
    </div>

    <!-- Filter Bar -->
    <div class="card" style="padding:12px 16px;">
      <div style="display:flex; align-items:center; gap:12px; flex-wrap:wrap;">
        <!-- Type tabs -->
        <div style="display:flex; gap:6px;">
          <button v-for="t in typeOptions" :key="t.value"
            @click="filterType = t.value; loadEntries()"
            :class="['btn btn-sm', filterType === t.value ? 'btn-primary' : '']"
            :style="filterType !== t.value ? 'background:var(--surface-2); color:var(--text-muted);' : ''">
            {{ t.label }}
          </button>
        </div>
        <div style="flex:1;"></div>
        <!-- Date range -->
        <DateRangePicker v-model="dateRange" @confirm="onFilterChange" />
      </div>
    </div>

    <!-- Table -->
    <div class="card" style="overflow:hidden;">
      <div style="overflow-x:auto;">
        <table class="table">
          <thead>
            <tr>
              <th>ວັນທີ</th>
              <th>ປະເພດ</th>
              <th>ໝວດ</th>
              <th>ລາຍລະອຽດ</th>
              <th>ເລກອ້າງອີງ</th>
              <th style="text-align:right;">ຈຳນວນ (ກີບ)</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="7"><div class="skeleton" style="height:20px;"></div></td>
            </tr>
            <tr v-else-if="!entries.length">
              <td colspan="7" style="text-align:center; color:var(--text-muted); padding:32px;">ບໍ່ມີລາຍການ</td>
            </tr>
            <tr v-else v-for="e in entries" :key="e.id">
              <td style="font-size:13px; white-space:nowrap;">{{ formatDate(e.entry_date) }}</td>
              <td>
                <span :class="`badge ${typeBadge(e.type)}`">{{ typeLabel(e.type) }}</span>
              </td>
              <td style="font-size:13px;">{{ e.category }}</td>
              <td style="font-size:13px; color:var(--text-muted); max-width:200px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">
                {{ e.description || '—' }}
              </td>
              <td style="font-size:12px; color:var(--text-muted);">{{ e.reference || '—' }}</td>
              <td style="text-align:right; font-weight:600;" :style="`color:${e.type === 'expense' ? 'var(--danger)' : e.type === 'income' ? 'var(--success)' : 'var(--cream)'}`">
                {{ e.type === 'expense' ? '-' : '+' }}{{ formatNumber(e.amount) }}
              </td>
              <td>
                <div style="display:flex; gap:4px; justify-content:flex-end;">
                  <button class="btn btn-sm" style="background:var(--surface-2); color:var(--text-muted);" @click="openEdit(e)">
                    <Pencil :size="12" />
                  </button>
                  <button class="btn btn-sm" style="background:rgba(248,113,113,0.1); color:var(--danger);" @click="confirmDelete(e)">
                    <Trash2 :size="12" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Totals row (server-computed over the whole date range, not just this page) -->
      <div v-if="entries.length" style="display:flex; justify-content:flex-end; gap:24px; padding:12px 16px; border-top:1px solid var(--border); font-size:13px;">
        <span style="color:var(--success);">ລາຍຮັບ: +{{ formatNumber(rangeIncome) }}</span>
        <span style="color:var(--danger);">ລາຍຈ່າຍ: -{{ formatNumber(rangeExpense) }}</span>
        <span :style="`font-weight:700; color:${rangeNet >= 0 ? 'var(--success)' : 'var(--danger)'}`">
          ສຸດທິ: {{ rangeNet >= 0 ? '+' : '' }}{{ formatNumber(rangeNet) }}
        </span>
      </div>
    </div>

    <!-- Modal: Add / Edit -->
    <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
      <div class="modal" style="width:460px; max-width:95vw;">
        <h3 style="font-size:15px; font-weight:700; margin-bottom:16px; color:var(--cream);">
          {{ editing ? 'ແກ້ໄຂລາຍການ' : 'ເພີ່ມລາຍການໃໝ່' }}
        </h3>

        <div style="display:flex; flex-direction:column; gap:12px;">
          <!-- Type -->
          <div>
            <label class="input-label">ປະເພດ *</label>
            <div style="display:flex; gap:8px; margin-top:6px;">
              <button v-for="t in typeOptions.slice(1)" :key="t.value"
                @click="form.type = t.value; form.category = ''"
                :class="['btn btn-sm', form.type === t.value ? 'btn-primary' : '']"
                :style="form.type !== t.value ? 'background:var(--surface-2); color:var(--text-secondary);' : ''">
                {{ t.label }}
              </button>
            </div>
          </div>

          <!-- Category -->
          <div>
            <label class="input-label">ໝວດ *</label>
            <select v-model="form.category" class="input" style="margin-top:6px;">
              <option value="">ເລືອກໝວດ</option>
              <option v-for="c in (categories[form.type] || [])" :key="c" :value="c">{{ c }}</option>
              <option value="__other__">ອື່ນໆ (ພິມເອງ)</option>
            </select>
            <input v-if="form.category === '__other__'" v-model="form.customCategory"
              class="input" placeholder="ພິມໝວດ..." style="margin-top:6px;" />
          </div>

          <!-- Amount -->
          <div>
            <label class="input-label">ຈຳນວນ (ກີບ) *</label>
            <input v-model.number="form.amount" type="number" min="0" class="input" placeholder="0" style="margin-top:6px;" />
          </div>

          <!-- Date -->
          <div>
            <label class="input-label">ວັນທີ *</label>
            <input v-model="form.entry_date" type="date" class="input" style="margin-top:6px;" />
          </div>

          <!-- Reference -->
          <div>
            <label class="input-label">ເລກບິນ / ອ້າງອີງ</label>
            <input v-model="form.reference" class="input" placeholder="ເລກໃບເກັບເງິນ, ໃບຮັບເງິນ..." style="margin-top:6px;" />
          </div>

          <!-- Description -->
          <div>
            <label class="input-label">ລາຍລະອຽດ</label>
            <textarea v-model="form.description" class="input" rows="2" placeholder="ໝາຍເຫດ / ລາຍລະອຽດເພີ່ມຕື່ມ" style="margin-top:6px; resize:vertical;"></textarea>
          </div>
        </div>

        <div style="display:flex; gap:8px; justify-content:flex-end; margin-top:16px;">
          <button class="btn" style="background:var(--surface-2); color:var(--text-muted);" @click="showModal = false">ຍົກເລີກ</button>
          <button class="btn btn-primary" :disabled="saving" @click="saveEntry">
            {{ saving ? 'ກຳລັງບັນທຶກ...' : (editing ? 'ບັນທຶກ' : 'ເພີ່ມ') }}
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Plus, Pencil, Trash2 } from 'lucide-vue-next'
import { financeApi } from '@/api/index.js'
import { formatNumber, formatCompact } from '@/utils/format.js'
import { useToastStore } from '@/stores/toast.js'
import DateRangePicker from '@/components/ui/DateRangePicker.vue'

const toast = useToastStore()

const summary = ref(null)
const entries = ref([])
const loading = ref(true)
const saving = ref(false)
const showModal = ref(false)
const editing = ref(null)
const categories = ref({})

const filterType = ref('')

function currentMonthRange() {
  const d = new Date()
  const start = new Date(d.getFullYear(), d.getMonth(), 1)
  const end = new Date(d.getFullYear(), d.getMonth() + 1, 0)
  return { start: start.toISOString().slice(0, 10), end: end.toISOString().slice(0, 10) }
}
const dateRange = ref(currentMonthRange())

const typeOptions = [
  { value: '', label: 'ທັງໝົດ' },
  { value: 'capital', label: 'ທຶນ' },
  { value: 'income', label: 'ລາຍຮັບ' },
  { value: 'expense', label: 'ລາຍຈ່າຍ' },
]

// Totals for the selected range come from the backend summary so they cover
// every entry, not just the (max 100) rows currently loaded in the table.
const rangeIncome = computed(() => summary.value?.month_income || 0)
const rangeExpense = computed(() => summary.value?.month_expense || 0)
const rangeNet = computed(() => summary.value?.month_net || 0)

const form = ref({ type: 'income', category: '', customCategory: '', amount: 0, entry_date: today(), reference: '', description: '' })

function today() {
  return new Date().toISOString().slice(0, 10)
}

function typeLabel(t) {
  return { income: 'ລາຍຮັບ', expense: 'ລາຍຈ່າຍ', capital: 'ທຶນ' }[t] || t
}
function typeBadge(t) {
  return { income: 'badge-success', expense: 'badge-danger', capital: 'badge-info' }[t] || 'badge-muted'
}
function formatDate(d) {
  if (!d) return '—'
  return new Date(d).toLocaleDateString('lo-LA', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

async function loadData() {
  const [sumRes, catRes] = await Promise.all([
    financeApi.summary({ date_from: dateRange.value.start, date_to: dateRange.value.end }),
    financeApi.categories(),
  ])
  summary.value = sumRes.data
  categories.value = catRes.data
}

async function loadEntries() {
  loading.value = true
  try {
    const params = { limit: 100 }
    if (filterType.value) params.type = filterType.value
    if (dateRange.value.start) params.date_from = dateRange.value.start
    if (dateRange.value.end) params.date_to = dateRange.value.end
    const res = await financeApi.list(params)
    entries.value = res.data.items
  } catch (e) {
    toast.error('ໂຫຼດຂໍ້ມູນບໍ່ສຳເລັດ')
  } finally {
    loading.value = false
  }
}

async function onFilterChange() {
  await Promise.all([loadData(), loadEntries()])
}

onMounted(async () => {
  await Promise.all([loadData(), loadEntries()])
})

function openCreate() {
  editing.value = null
  form.value = { type: 'income', category: '', customCategory: '', amount: 0, entry_date: today(), reference: '', description: '' }
  showModal.value = true
}

function openEdit(e) {
  editing.value = e
  form.value = {
    type: e.type,
    category: e.category,
    customCategory: '',
    amount: e.amount,
    entry_date: e.entry_date,
    reference: e.reference || '',
    description: e.description || '',
  }
  showModal.value = true
}

async function saveEntry() {
  const cat = form.value.category === '__other__' ? form.value.customCategory : form.value.category
  if (!form.value.type || !cat || !form.value.amount || !form.value.entry_date) {
    toast.error('ກະລຸນາໃສ່ຂໍ້ມູນໃຫ້ຄົບ')
    return
  }
  saving.value = true
  try {
    const payload = {
      type: form.value.type,
      category: cat,
      amount: form.value.amount,
      entry_date: form.value.entry_date,
      reference: form.value.reference || null,
      description: form.value.description || null,
    }
    if (editing.value) {
      await financeApi.update(editing.value.id, payload)
      toast.success('ແກ້ໄຂສຳເລັດ')
    } else {
      await financeApi.create(payload)
      toast.success('ເພີ່ມລາຍການສຳເລັດ')
    }
    showModal.value = false
    await Promise.all([loadData(), loadEntries()])
  } catch (e) {
    toast.error('ບັນທຶກບໍ່ສຳເລັດ')
  } finally {
    saving.value = false
  }
}

async function confirmDelete(e) {
  if (!confirm(`ລຶບລາຍການ "${e.category}" ${formatNumber(e.amount)} ກີບ?`)) return
  try {
    await financeApi.delete(e.id)
    toast.success('ລຶບສຳເລັດ')
    await Promise.all([loadData(), loadEntries()])
  } catch {
    toast.error('ລຶບບໍ່ສຳເລັດ')
  }
}
</script>
