<template>
  <div>
    <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:24px;">
      <div>
        <h1 style="font-family:'Noto Serif Lao', serif; font-size:20px; font-weight:700; color:var(--cream);">Analytics</h1>
        <p style="font-size:13px; color:var(--text-muted);">ຂໍ້ມູນ ແລະ ການວິເຄາະທຸລະກິດ</p>
      </div>
      <select v-model="days" class="input" style="width:auto;" @change="loadRevenue">
        <option :value="30">30 ວັນ</option>
        <option :value="60">60 ວັນ</option>
        <option :value="90">90 ວັນ</option>
      </select>
    </div>

    <!-- Revenue chart -->
    <div class="card" style="margin-bottom:16px;">
      <div class="card-header">
        <span style="font-size:14px; font-weight:600; color:var(--text);">ລາຍຮັບ {{ days }} ວັນ</span>
        <span style="font-size:11px; color:var(--text-muted);">ກີບ</span>
      </div>
      <div v-if="revenueLoading" class="skeleton" style="height:260px;"></div>
      <LineChart v-else :data="revenue" :height="260" label="ລາຍຮັບ" />
    </div>

    <div style="display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-bottom:16px;">
      <!-- Top shops -->
      <div class="card">
        <div class="card-header"><span style="font-size:14px; font-weight:600; color:var(--text);">ຮ້ານ Top 10</span></div>
        <div v-if="shopsLoading" class="skeleton" style="height:250px;"></div>
        <BarChart v-else :data="topShops" :height="250" label-key="name" value-key="credit_used" />
      </div>

      <!-- Geography -->
      <div class="card">
        <div class="card-header"><span style="font-size:14px; font-weight:600; color:var(--text);">ຮ້ານຕາມແຂວງ</span></div>
        <div v-if="geoLoading" class="skeleton" style="height:250px;"></div>
        <BarChart v-else :data="geography" :height="250" label-key="province" value-key="count" :horizontal="false" color="#6EE7A7" />
      </div>
    </div>

    <!-- Top products table -->
    <div class="card">
      <div class="card-header"><span style="font-size:14px; font-weight:600; color:var(--text);">ສິນຄ້ານິຍົມ</span></div>
      <div class="table-wrapper">
        <table class="table">
          <thead>
            <tr><th>ສິນຄ້າ</th><th>ໝວດ</th><th>ລາຄາ</th><th>ສະຕັອກ</th></tr>
          </thead>
          <tbody>
            <tr v-if="productsLoading"><td colspan="4"><div class="skeleton" style="height:20px;"></div></td></tr>
            <tr v-for="(p, i) in topProducts" :key="p.name">
              <td style="display:flex; align-items:center; gap:10px;">
                <span style="font-size:11px; color:var(--text-muted); font-family:Manrope; width:18px;">{{ i+1 }}</span>
                <span style="color:var(--text);">{{ p.name }}</span>
              </td>
              <td><span class="badge badge-muted">{{ p.category }}</span></td>
              <td class="num">{{ formatCurrency(p.price) }}</td>
              <td class="num">{{ p.stock }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import LineChart from '@/components/charts/LineChart.vue'
import BarChart from '@/components/charts/BarChart.vue'
import { analyticsApi } from '@/api/index.js'
import { formatCurrency } from '@/utils/format.js'

const days = ref(90)
const revenue = ref([])
const topShops = ref([])
const geography = ref([])
const topProducts = ref([])
const revenueLoading = ref(true)
const shopsLoading = ref(true)
const geoLoading = ref(true)
const productsLoading = ref(true)

async function loadRevenue() {
  revenueLoading.value = true
  const { data } = await analyticsApi.revenue(days.value)
  revenue.value = data
  revenueLoading.value = false
}

onMounted(async () => {
  const [revRes, shopsRes, geoRes, productsRes] = await Promise.all([
    analyticsApi.revenue(days.value),
    analyticsApi.topShops(10),
    analyticsApi.geography(),
    analyticsApi.topProducts(10),
  ])
  revenue.value = revRes.data; revenueLoading.value = false
  topShops.value = shopsRes.data; shopsLoading.value = false
  geography.value = geoRes.data; geoLoading.value = false
  topProducts.value = productsRes.data; productsLoading.value = false
})
</script>
