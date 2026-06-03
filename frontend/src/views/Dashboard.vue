<template>
  <div style="display:flex; flex-direction:column; gap:16px;">

    <!-- Header -->
    <div style="display:flex; align-items:center; justify-content:space-between;">
      <div>
        <h1 style=" font-size:20px; font-weight:700; color:var(--cream);">Dashboard</h1>
        <p style="color:var(--text-muted); font-size:13px; margin-top:2px;">ພາບລວມທຸລະກິດ Filby Coffee</p>
      </div>
    </div>

    <!-- KPI Cards Row 1: Operations -->
    <div style="display:grid; grid-template-columns:repeat(4, 1fr); gap:16px;">
      <KpiCard label="ຮ້ານທັງໝົດ" :value="formatNumber(kpis?.total_shops)" :sub="`+${kpis?.new_shops_this_month || 0} ໃໝ່ເດືອນນີ້`" :icon="Store" icon-bg="rgba(110,231,167,0.1)" icon-color="var(--success)" :loading="kpiLoading" />
      <KpiCard label="ສິນເຊື່ອທີ່ໃຊ້ຢູ່" :value="formatCompact(kpis?.active_credit) + ' ກີບ'" :icon="CreditCard" :loading="kpiLoading" />
      <KpiCard label="ຄຳສະໝັກລໍຖ້າ" :value="formatNumber(kpis?.pending_apps)" sub="ຕ້ອງ Review" :icon="FileText" icon-bg="rgba(251,191,36,0.1)" icon-color="var(--warning)" :loading="kpiLoading" />
      <KpiCard label="ລາຍຮັບເດືອນນີ້" :value="formatCompact(kpis?.monthly_revenue) + ' ກີບ'" :sub="kpis?.revenue_change > 0 ? `+${kpis.revenue_change}%` : `${kpis?.revenue_change || 0}%`" :trend="kpis?.revenue_change" :icon="TrendingUp" :loading="kpiLoading" />
    </div>

    <!-- KPI Cards Row 2: Finance -->
    <div style="display:grid; grid-template-columns:repeat(4, 1fr); gap:16px;">
      <KpiCard label="ທຶນລວມ" :value="formatCompact(kpis?.total_capital) + ' ກີບ'" :icon="Landmark" icon-bg="rgba(99,179,237,0.1)" icon-color="#63B3ED" :loading="kpiLoading" sub-label="ທຶນທີ່ລົງທຶນທັງໝົດ" />
      <KpiCard label="ລາຍຮັບເດືອນນີ້" :value="formatCompact(kpis?.finance_income) + ' ກີບ'" :icon="ArrowDownCircle" icon-bg="rgba(110,231,167,0.1)" icon-color="var(--success)" :loading="kpiLoading" sub-label="ລາຍຮັບຈາກການດຳເນີນງານ" />
      <KpiCard label="ລາຍຈ່າຍເດືອນນີ້" :value="formatCompact(kpis?.finance_expense) + ' ກີບ'" :icon="ArrowUpCircle" icon-bg="rgba(248,113,113,0.1)" icon-color="var(--danger)" :loading="kpiLoading" sub-label="ຄ່າໃຊ້ຈ່າຍດຳເນີນງານ" />
      <KpiCard
        label="ກຳໄລ / ຂາດທຶນ"
        :value="(kpis?.finance_net >= 0 ? '+' : '') + formatCompact(kpis?.finance_net) + ' ກີບ'"
        :icon="TrendingUp"
        :icon-bg="(kpis?.finance_net ?? 0) >= 0 ? 'rgba(110,231,167,0.1)' : 'rgba(248,113,113,0.1)'"
        :icon-color="(kpis?.finance_net ?? 0) >= 0 ? 'var(--success)' : 'var(--danger)'"
        :trend="kpis?.finance_net"
        :loading="kpiLoading"
        sub-label="ເດືອນນີ້ (ລາຍຮັບ - ລາຍຈ່າຍ)"
      />
    </div>

    <!-- Revenue / Expense Chart (full width) -->
    <div class="card">
      <div class="card-header">
        <div style="display:flex; align-items:center; gap:16px; flex-wrap:wrap;">
          <span style="font-size:14px; font-weight:600; color:var(--text);">ລາຍຮັບ & ສິນເຊື່ອ & ກຳໄລ/ຂາດທຶນ</span>
          <span style="font-size:11px; color:var(--text-muted);">12 ເດືອນຜ່ານມາ</span>
        </div>
        <div style="display:flex; gap:14px; font-size:11px; color:rgba(255,250,243,0.65);">
          <span><span style="display:inline-block;width:10px;height:10px;background:#6EE7A7;border-radius:2px;margin-right:4px;vertical-align:middle;"></span>ລາຍຮັບ</span>
          <span><span style="display:inline-block;width:10px;height:10px;background:#E8854A;border-radius:2px;margin-right:4px;vertical-align:middle;"></span>ສິນເຊື່ອອອກ</span>
          <span><span style="display:inline-block;width:18px;height:2px;background:#FACC15;margin-right:4px;vertical-align:middle;border-radius:1px;"></span>ກຳໄລ/ຂາດທຶນ</span>
        </div>
      </div>
      <div v-if="revenueLoading" class="skeleton" style="height:240px;"></div>
      <RevenueChart v-else :data="revenueExpense" :height="240" />
    </div>

    <!-- Bottom Row: Credit Trend + Top Shops + Activity -->
    <div style="display:grid; grid-template-columns:1fr 1fr 320px; gap:16px;">

      <!-- Credit trend -->
      <div class="card">
        <div class="card-header">
          <span style="font-size:14px; font-weight:600; color:var(--text);">ສິນເຊື່ອອອກ 30 ມື້</span>
          <span style="font-size:11px; color:var(--text-muted);">ກີບ</span>
        </div>
        <div v-if="chartLoading" class="skeleton" style="height:200px;"></div>
        <LineChart v-else :data="creditTrend" :height="200" />
      </div>

      <!-- Top shops -->
      <div class="card">
        <div class="card-header">
          <span style="font-size:14px; font-weight:600; color:var(--text);">Top 10 ຮ້ານ</span>
          <span style="font-size:11px; color:var(--text-muted);">ໂດຍສິນເຊື່ອ</span>
        </div>
        <div v-if="chartLoading" class="skeleton" style="height:200px;"></div>
        <BarChart v-else :data="topShops" :height="200" label-key="name" value-key="credit_used" />
      </div>

      <!-- Activity Feed -->
      <div class="card" style="overflow:hidden;">
        <div class="card-header">
          <span style="font-size:14px; font-weight:600; color:var(--text);">ກິດຈະກຳລ່າສຸດ</span>
        </div>
        <div style="overflow-y:auto; max-height:230px; display:flex; flex-direction:column; gap:2px;">
          <template v-if="activityLoading">
            <div v-for="i in 5" :key="i" class="skeleton" style="height:52px; margin-bottom:6px; border-radius:8px;"></div>
          </template>
          <template v-else>
            <div v-for="item in activityItems" :key="item.id + item.type" class="activity-item" @click="handleActivityClick(item)">
              <div :class="`activity-icon ${item.type}`">
                <FileText v-if="item.type === 'new_application'" :size="13" />
                <CheckCircle v-else-if="item.type === 'payment'" :size="13" />
                <AlertTriangle v-else :size="13" />
              </div>
              <div style="flex:1; min-width:0;">
                <div style="font-size:12px; color:var(--text); font-weight:500; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">{{ item.shop_name }}</div>
                <div style="font-size:11px; color:var(--text-muted);">
                  <span v-if="item.type === 'new_application'">ສະໝັກ {{ formatCompact(item.credit_requested) }} ກີບ</span>
                  <span v-else-if="item.type === 'payment'">ຈ່າຍ {{ formatCompact(item.amount) }} ກີບ</span>
                  <span v-else>ສິນເຊື່ອ {{ formatCompact(item.credit_used) }} ກີບ</span>
                </div>
              </div>
              <div v-if="item.type === 'new_application'" style="display:flex; gap:4px;">
                <button class="btn btn-sm" style="background:rgba(110,231,167,0.15); color:var(--success); border:none; padding:3px 8px; font-size:10px;" @click.stop="quickApprove(item)">Approve</button>
              </div>
            </div>
            <div v-if="!activityItems.length" class="empty-state" style="padding:20px;">
              <div style="font-size:12px;">ບໍ່ມີກິດຈະກຳ</div>
            </div>
          </template>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { Store, CreditCard, FileText, TrendingUp, CheckCircle, AlertTriangle, Landmark, ArrowDownCircle, ArrowUpCircle } from 'lucide-vue-next'
import KpiCard from '@/components/dashboard/KpiCard.vue'
import LineChart from '@/components/charts/LineChart.vue'
import BarChart from '@/components/charts/BarChart.vue'
import RevenueChart from '@/components/charts/RevenueChart.vue'
import { dashboardApi } from '@/api/index.js'
import { formatNumber, formatCompact } from '@/utils/format.js'

const router = useRouter()
const kpis = ref(null)
const kpiLoading = ref(true)
const chartLoading = ref(true)
const revenueLoading = ref(true)
const activityLoading = ref(true)
const creditTrend = ref([])
const topShops = ref([])
const revenueExpense = ref([])
const recent = ref({})

const activityItems = computed(() => {
  const apps = (recent.value.applications || []).map(a => ({ ...a, type: 'new_application' }))
  const payments = (recent.value.payments || []).map(p => ({ ...p, type: 'payment' }))
  return [...apps, ...payments].slice(0, 8)
})

onMounted(async () => {
  try {
    const [kpisRes, trendRes, shopsRes, recentRes, revenueRes] = await Promise.all([
      dashboardApi.kpis(),
      dashboardApi.creditTrend(30),
      dashboardApi.topShops(10),
      dashboardApi.recent(),
      dashboardApi.revenueExpense(12),
    ])
    kpis.value = kpisRes.data
    creditTrend.value = trendRes.data
    topShops.value = shopsRes.data
    recent.value = recentRes.data
    revenueExpense.value = revenueRes.data
  } catch (e) {
    console.error(e)
  } finally {
    kpiLoading.value = false
    chartLoading.value = false
    revenueLoading.value = false
    activityLoading.value = false
  }
})

function handleActivityClick(item) {
  if (item.type === 'new_application') router.push(`/applications/${item.id}`)
  else if (item.type === 'payment' && item.shop_id) router.push(`/shops/${item.shop_id}`)
}

function quickApprove(item) {
  router.push(`/applications/${item.id}`)
}
</script>

<style scoped>
.activity-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.1s;
}
.activity-item:hover { background: var(--surface-2); }
.activity-icon {
  width: 28px; height: 28px; border-radius: 8px;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.activity-icon.new_application { background: rgba(251,191,36,0.15); color: var(--warning); }
.activity-icon.payment { background: rgba(110,231,167,0.15); color: var(--success); }
.activity-icon.overdue { background: rgba(248,113,113,0.15); color: var(--danger); }
</style>
