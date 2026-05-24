<template>
  <div style="display:flex; flex-direction:column; gap:16px;">

    <!-- Header -->
    <div style="display:flex; align-items:center; justify-content:space-between;">
      <div>
        <h1 style="font-size:20px; font-weight:700; color:var(--cream);">ເກັບກຳຂໍ້ມູນຮ້ານ</h1>
        <p style="color:var(--text-muted); font-size:13px; margin-top:2px;">ສຳຫຼວດລູກຄ້າ ແລະ ວິເຄາະຄວາມສົນໃຈ</p>
      </div>
      <button class="btn btn-primary" @click="openForm(null)">+ ເພີ່ມຂໍ້ມູນຮ້ານ</button>
    </div>

    <!-- Analytics Cards -->
    <div style="display:grid; grid-template-columns:repeat(5,1fr); gap:12px;">
      <div class="card" style="padding:16px; text-align:center;">
        <div style="font-size:11px; color:var(--text-muted); margin-bottom:6px;">ທັງໝົດ</div>
        <div style="font-size:24px; font-weight:700; color:var(--text);">{{ stats.total }}</div>
      </div>
      <div class="card" style="padding:16px; text-align:center; border-color:rgba(110,231,167,0.25);">
        <div style="font-size:11px; color:var(--text-muted); margin-bottom:6px;">ສົນໃຈ</div>
        <div style="font-size:24px; font-weight:700; color:var(--success);">{{ stats.interested }}</div>
        <div style="font-size:10px; color:var(--text-muted);">{{ interestedPct }}%</div>
      </div>
      <div class="card" style="padding:16px; text-align:center; border-color:rgba(248,113,113,0.25);">
        <div style="font-size:11px; color:var(--text-muted); margin-bottom:6px;">ບໍ່ສົນໃຈ</div>
        <div style="font-size:24px; font-weight:700; color:var(--danger);">{{ stats.not_interested }}</div>
      </div>
      <div class="card" style="padding:16px; text-align:center; border-color:rgba(251,191,36,0.25);">
        <div style="font-size:11px; color:var(--text-muted); margin-bottom:6px;">ຍັງບໍ່ແນ່ໃຈ</div>
        <div style="font-size:24px; font-weight:700; color:var(--warning);">{{ stats.undecided }}</div>
      </div>
      <div class="card" style="padding:16px; text-align:center; border-color:rgba(201,160,71,0.25);">
        <div style="font-size:11px; color:var(--text-muted); margin-bottom:6px;">ເຉລ່ຍ ກາເຟ/ມື້</div>
        <div style="font-size:24px; font-weight:700; color:var(--primary);">{{ stats.avg_daily_kg }}</div>
        <div style="font-size:10px; color:var(--text-muted);">ກິໂລ</div>
      </div>
    </div>

    <!-- Charts -->
    <div style="display:grid; grid-template-columns:300px 1fr; gap:16px;">
      <!-- Pie chart -->
      <div class="card">
        <div class="card-header">
          <span style="font-size:14px; font-weight:600; color:var(--text);">ສັດສ່ວນຄວາມສົນໃຈ</span>
        </div>
        <div ref="pieEl" style="width:100%; height:220px;"></div>
      </div>
      <!-- Bar by province -->
      <div class="card">
        <div class="card-header">
          <span style="font-size:14px; font-weight:600; color:var(--text);">ຮ້ານຕາມແຂວງ</span>
        </div>
        <div ref="barEl" style="width:100%; height:220px;"></div>
      </div>
    </div>

    <!-- Filters + Table -->
    <div class="card" style="padding:0; overflow:hidden;">
      <div style="display:flex; gap:10px; padding:16px; border-bottom:1px solid var(--border);">
        <div class="search-bar" style="flex:1;">
          <Search :size="14" class="search-icon" />
          <input v-model="search" class="input" placeholder="ຊອກຫາຊື່ຮ້ານ, ເຈົ້າຂອງ, ເບີໂທ..." style="padding-left:32px;" />
        </div>
        <select v-model="filterInterest" class="input" style="width:160px;">
          <option value="">ທຸກສະຖານະ</option>
          <option value="interested">ສົນໃຈ</option>
          <option value="not_interested">ບໍ່ສົນໃຈ</option>
          <option value="undecided">ຍັງບໍ່ແນ່ໃຈ</option>
        </select>
        <select v-model="filterProvince" class="input" style="width:160px;">
          <option value="">ທຸກແຂວງ</option>
          <option v-for="pv in provinces" :key="pv" :value="pv">{{ pv }}</option>
        </select>
      </div>

      <div class="table-wrapper">
        <table class="table">
          <thead>
            <tr>
              <th>#</th>
              <th>ຊື່ຮ້ານ</th>
              <th>ເຈົ້າຂອງ</th>
              <th>ເບີໂທ</th>
              <th>ບ້ານ / ເມືອງ / ແຂວງ</th>
              <th>ກາເຟ/ມື້ (kg)</th>
              <th>ກາເຟ/ອາທິດ (kg)</th>
              <th>ສົນໃຈ</th>
              <th>ດຳເນີນການ</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading"><td colspan="9" style="text-align:center; padding:32px; color:var(--text-muted);">ກຳລັງໂຫລດ...</td></tr>
            <tr v-else-if="!items.length"><td colspan="9" style="text-align:center; padding:32px; color:var(--text-muted);">ຍັງບໍ່ມີຂໍ້ມູນ</td></tr>
            <tr v-for="p in items" :key="p.id" v-else>
              <td>{{ p.id }}</td>
              <td style="font-weight:500; color:var(--text);">{{ p.shop_name }}</td>
              <td>{{ p.owner_name }}</td>
              <td>{{ p.phone || '-' }}</td>
              <td style="font-size:12px;">{{ [p.village, p.district, p.province].filter(Boolean).join(' / ') || '-' }}</td>
              <td>{{ p.daily_coffee_kg }}</td>
              <td>{{ p.weekly_coffee_kg }}</td>
              <td>
                <span :class="`badge ${interestBadge(p.interest)}`">{{ interestLabel(p.interest) }}</span>
              </td>
              <td>
                <div style="display:flex; gap:6px;">
                  <button class="btn btn-sm btn-ghost" @click.stop="openForm(p)">ແກ້ໄຂ</button>
                  <button class="btn btn-sm btn-danger" @click.stop="deleteItem(p)">ລົບ</button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Modal Form -->
    <div v-if="showModal" class="modal-overlay" @click.self="showModal=false">
      <div class="modal" style="max-width:560px; max-height:90vh; overflow-y:auto;">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:20px;">
          <h3 style="font-size:16px; font-weight:600; color:var(--text);">{{ editing ? 'ແກ້ໄຂ' : 'ເພີ່ມ' }}ຂໍ້ມູນຮ້ານ</h3>
          <button @click="showModal=false" style="background:none; border:none; cursor:pointer; color:var(--text-muted);">✕</button>
        </div>

        <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
          <div class="form-group">
            <label class="input-label">ຊື່ຮ້ານ *</label>
            <input v-model="form.shop_name" class="input" placeholder="ຊື່ຮ້ານກາເຟ" />
          </div>
          <div class="form-group">
            <label class="input-label">ຊື່ເຈົ້າຂອງ *</label>
            <input v-model="form.owner_name" class="input" placeholder="ຊື່-ນາມສະກຸນ" />
          </div>
          <div class="form-group">
            <label class="input-label">ເບີໂທ</label>
            <input v-model="form.phone" class="input" placeholder="020 XXXXXXXX" />
          </div>
          <div class="form-group">
            <label class="input-label">ບ້ານ</label>
            <input v-model="form.village" class="input" placeholder="ບ້ານ..." />
          </div>
          <div class="form-group">
            <label class="input-label">ເມືອງ</label>
            <input v-model="form.district" class="input" placeholder="ເມືອງ..." />
          </div>
          <div class="form-group">
            <label class="input-label">ແຂວງ</label>
            <select v-model="form.province" class="input">
              <option value="">ເລືອກແຂວງ</option>
              <option v-for="pv in LAO_PROVINCES" :key="pv" :value="pv">{{ pv }}</option>
            </select>
          </div>
          <div class="form-group">
            <label class="input-label">GPS Latitude</label>
            <input v-model.number="form.lat" class="input" type="number" step="0.0001" placeholder="18.1234" />
          </div>
          <div class="form-group">
            <label class="input-label">GPS Longitude</label>
            <input v-model.number="form.lng" class="input" type="number" step="0.0001" placeholder="102.1234" />
          </div>
          <div class="form-group">
            <label class="input-label">ໃຊ້ກາເຟ/ມື້ (ກິໂລ)</label>
            <input v-model.number="form.daily_coffee_kg" class="input" type="number" step="0.1" min="0" placeholder="0.0" @input="calcWeekly" />
          </div>
          <div class="form-group">
            <label class="input-label">ໃຊ້ກາເຟ/ອາທິດ (ກິໂລ)</label>
            <input v-model.number="form.weekly_coffee_kg" class="input" type="number" step="0.1" min="0" placeholder="0.0" />
          </div>
          <div class="form-group" style="grid-column:1/-1;">
            <label class="input-label">ຄວາມສົນໃຈ BNPL Filby Coffee</label>
            <div style="display:flex; gap:10px; margin-top:4px;">
              <label v-for="opt in interestOptions" :key="opt.value"
                :style="`flex:1; display:flex; align-items:center; justify-content:center; gap:6px; padding:10px; border-radius:8px; cursor:pointer; border:1px solid; transition:all 0.15s;
                  border-color:${form.interest===opt.value ? opt.color+'80' : 'var(--border)'};
                  background:${form.interest===opt.value ? opt.color+'15' : 'transparent'};
                  color:${form.interest===opt.value ? opt.color : 'var(--text-secondary)'}`">
                <input type="radio" v-model="form.interest" :value="opt.value" style="display:none" />
                {{ opt.label }}
              </label>
            </div>
          </div>
          <div class="form-group" style="grid-column:1/-1;">
            <label class="input-label">ໝາຍເຫດ</label>
            <textarea v-model="form.notes" class="input" rows="2" placeholder="ໝາຍເຫດເພີ່ມເຕີມ..." style="resize:vertical;"></textarea>
          </div>
        </div>

        <div style="display:flex; gap:10px; justify-content:flex-end; margin-top:16px;">
          <button class="btn btn-ghost" @click="showModal=false">ຍົກເລີກ</button>
          <button class="btn btn-primary" @click="save" :disabled="saving">
            {{ saving ? 'ກຳລັງບັນທຶກ...' : 'ບັນທຶກ' }}
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import { Search } from 'lucide-vue-next'
import * as echarts from 'echarts'
import client from '@/api/client.js'

const LAO_PROVINCES = [
  'ວຽງຈັນ ນະຄອນ','ວຽງຈັນ','ຫຼວງພະບາງ','ສາວັນນະເຂດ','ຈຳປາສັກ','ຫຼວງນ້ຳທາ',
  'ອຸດົມໄຊ','ບໍ່ແກ້ວ','ຜົ້ງສາລີ','ຫົວພັນ','ຊຽງຂວາງ','ຄຳມ່ວນ',
  'ສາລະວັນ','ເຊກອງ','ອັດຕະປື','ໄຊສົມບູນ',
]

const interestOptions = [
  { value: 'interested', label: 'ສົນໃຈ', color: '#6EE7A7' },
  { value: 'not_interested', label: 'ບໍ່ສົນໃຈ', color: '#F87171' },
  { value: 'undecided', label: 'ຍັງບໍ່ແນ່ໃຈ', color: '#FBBF24' },
]

const items = ref([])
const stats = ref({ total: 0, interested: 0, not_interested: 0, undecided: 0, avg_daily_kg: 0, by_province: [] })
const loading = ref(true)
const saving = ref(false)
const showModal = ref(false)
const editing = ref(null)
const search = ref('')
const filterInterest = ref('')
const filterProvince = ref('')

const emptyForm = () => ({
  shop_name: '', owner_name: '', phone: '', village: '', district: '', province: '',
  lat: null, lng: null, daily_coffee_kg: 0, weekly_coffee_kg: 0, interest: 'undecided', notes: '',
})
const form = ref(emptyForm())

const interestedPct = computed(() => stats.value.total ? Math.round(stats.value.interested / stats.value.total * 100) : 0)
const provinces = computed(() => [...new Set(items.value.map(i => i.province).filter(Boolean))])

function calcWeekly() {
  if (form.value.daily_coffee_kg) {
    form.value.weekly_coffee_kg = Math.round(form.value.daily_coffee_kg * 7 * 10) / 10
  }
}

function interestLabel(v) {
  return { interested: 'ສົນໃຈ', not_interested: 'ບໍ່ສົນໃຈ', undecided: 'ຍັງບໍ່ແນ່ໃຈ' }[v] || v
}
function interestBadge(v) {
  return { interested: 'badge-success', not_interested: 'badge-danger', undecided: 'badge-warning' }[v] || 'badge-muted'
}

async function load() {
  loading.value = true
  const params = {}
  if (search.value) params.search = search.value
  if (filterInterest.value) params.interest = filterInterest.value
  if (filterProvince.value) params.province = filterProvince.value
  const [listRes, statsRes] = await Promise.all([
    client.get('/api/prospects', { params }),
    client.get('/api/prospects/analytics'),
  ])
  items.value = listRes.data.items
  stats.value = statsRes.data
  loading.value = false
  await nextTick()
  renderCharts()
}

function openForm(p) {
  editing.value = p
  form.value = p ? { ...p } : emptyForm()
  showModal.value = true
}

async function save() {
  if (!form.value.shop_name || !form.value.owner_name) return
  saving.value = true
  try {
    if (editing.value) {
      await client.put(`/api/prospects/${editing.value.id}`, form.value)
    } else {
      await client.post('/api/prospects', form.value)
    }
    showModal.value = false
    await load()
  } finally {
    saving.value = false
  }
}

async function deleteItem(p) {
  if (!confirm(`ລົບ "${p.shop_name}"?`)) return
  await client.delete(`/api/prospects/${p.id}`)
  await load()
}

// Charts
const pieEl = ref(null)
const barEl = ref(null)
let pieChart = null
let barChart = null

function renderCharts() {
  // Pie
  if (pieEl.value) {
    if (!pieChart) pieChart = echarts.init(pieEl.value, null, { renderer: 'svg' })
    pieChart.setOption({
      backgroundColor: 'transparent',
      textStyle: { fontFamily: 'Noto Sans Lao, sans-serif' },
      tooltip: { trigger: 'item', backgroundColor: '#0F1828', borderColor: 'rgba(180,210,255,0.14)', textStyle: { color: '#F0F4FF', fontSize: 12 } },
      series: [{
        type: 'pie', radius: ['40%', '70%'], center: ['50%', '50%'],
        label: { color: 'rgba(240,244,255,0.7)', fontSize: 11, fontFamily: 'Noto Sans Lao, sans-serif' },
        data: [
          { value: stats.value.interested, name: 'ສົນໃຈ', itemStyle: { color: '#6EE7A7' } },
          { value: stats.value.not_interested, name: 'ບໍ່ສົນໃຈ', itemStyle: { color: '#F87171' } },
          { value: stats.value.undecided, name: 'ຍັງບໍ່ແນ່ໃຈ', itemStyle: { color: '#FBBF24' } },
        ],
      }],
    })
  }
  // Bar by province
  if (barEl.value && stats.value.by_province.length) {
    if (!barChart) barChart = echarts.init(barEl.value, null, { renderer: 'svg' })
    const provs = stats.value.by_province.sort((a, b) => b.total - a.total).slice(0, 10)
    barChart.setOption({
      backgroundColor: 'transparent',
      textStyle: { fontFamily: 'Noto Sans Lao, sans-serif' },
      grid: { top: 10, right: 16, bottom: 32, left: 80 },
      tooltip: { trigger: 'axis', backgroundColor: '#0F1828', borderColor: 'rgba(180,210,255,0.14)', textStyle: { color: '#F0F4FF', fontSize: 12 } },
      xAxis: { type: 'value', axisLabel: { color: 'rgba(240,244,255,0.4)', fontSize: 10 }, splitLine: { lineStyle: { color: 'rgba(180,210,255,0.05)' } }, axisLine: { show: false } },
      yAxis: { type: 'category', data: provs.map(p => p.province), axisLabel: { color: 'rgba(240,244,255,0.6)', fontSize: 11 }, axisLine: { lineStyle: { color: 'rgba(180,210,255,0.08)' } }, splitLine: { show: false } },
      series: [
        { name: 'ສົນໃຈ', type: 'bar', stack: 'a', data: provs.map(p => p.interested), itemStyle: { color: '#6EE7A7', borderRadius: [0, 0, 0, 0] }, barMaxWidth: 20 },
        { name: 'ບໍ່ສົນໃຈ', type: 'bar', stack: 'a', data: provs.map(p => p.not_interested), itemStyle: { color: '#F87171' }, barMaxWidth: 20 },
        { name: 'ຍັງບໍ່ແນ່ໃຈ', type: 'bar', stack: 'a', data: provs.map(p => p.undecided), itemStyle: { color: '#FBBF24', borderRadius: [0, 4, 4, 0] }, barMaxWidth: 20 },
      ],
    })
  }
}

let searchTimer = null
watch([search, filterInterest, filterProvince], () => {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(load, 300)
})

onMounted(load)
</script>
