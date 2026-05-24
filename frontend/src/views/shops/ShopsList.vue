<template>
  <div>
    <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:24px;">
      <div>
        <h1 style=" font-size:20px; font-weight:700; color:var(--cream);">ຮ້ານກາເຟ</h1>
        <p style="font-size:13px; color:var(--text-muted);">ທັງໝົດ {{ total }} ຮ້ານ</p>
      </div>
    </div>

    <!-- Filters -->
    <div class="card" style="margin-bottom:16px; padding:16px;">
      <div style="display:flex; gap:12px; flex-wrap:wrap; align-items:center;">
        <div class="search-bar" style="flex:1; min-width:220px; max-width:340px;">
          <Search :size="14" class="search-icon" />
          <input v-model="search" class="input" placeholder="ຄົ້ນຫາຮ້ານ, ເຈົ້າຂອງ, ID..." @input="onSearch" />
        </div>
        <select v-model="filterProvince" class="input" style="width:auto;" @change="loadShops(1)">
          <option value="">ທຸກແຂວງ</option>
          <option v-for="p in provinces" :key="p">{{ p }}</option>
        </select>
        <select v-model="filterStatus" class="input" style="width:auto;" @change="loadShops(1)">
          <option value="">ທຸກສະຖານະ</option>
          <option value="active">ເປີດໃຊ້ງານ</option>
          <option value="suspended">Suspended</option>
          <option value="pending">ລໍຖ້າ</option>
        </select>
        <select v-model="filterTier" class="input" style="width:auto;" @change="loadShops(1)">
          <option value="">ທຸກ Tier</option>
          <option value="gold">Gold</option>
          <option value="silver">Silver</option>
          <option value="bronze">Bronze</option>
        </select>
        <button class="btn btn-ghost btn-sm" @click="exportExcel">
          <Download :size="13" /> Export Excel
        </button>
      </div>
    </div>

    <!-- Table -->
    <div class="card" style="padding:0; overflow:hidden;">
      <div class="table-wrapper">
        <table class="table">
          <thead>
            <tr>
              <th>Shop ID</th>
              <th>ຊື່ຮ້ານ</th>
              <th>ເຈົ້າຂອງ</th>
              <th>ແຂວງ</th>
              <th>ສິນເຊື່ອ (ໃຊ້/ສູງສຸດ)</th>
              <th>Tier</th>
              <th>ສະຖານະ</th>
              <th>ວັນສະໝັກ</th>
            </tr>
          </thead>
          <tbody>
            <template v-if="loading">
              <tr v-for="i in 8" :key="i">
                <td colspan="8"><div class="skeleton" style="height:16px;"></div></td>
              </tr>
            </template>
            <template v-else-if="shops.length">
              <tr v-for="shop in shops" :key="shop.id" @click="router.push(`/shops/${shop.id}`)">
                <td><span class="num" style="color:var(--primary); font-size:12px;">{{ shop.shop_id || '-' }}</span></td>
                <td style="color:var(--text); font-weight:500;">{{ shop.name }}</td>
                <td>{{ shop.owner_name }}</td>
                <td>{{ shop.province }}</td>
                <td>
                  <div style="display:flex; flex-direction:column; gap:2px;">
                    <div class="num" style="font-size:12px;">{{ formatCompact(shop.credit_used) }} / {{ formatCompact(shop.credit_limit) }}</div>
                    <div style="height:3px; background:var(--surface-3); border-radius:2px; width:80px;">
                      <div :style="`height:100%; border-radius:2px; width:${Math.min(100, shop.credit_limit ? (shop.credit_used/shop.credit_limit)*100 : 0)}%; background:${creditColor(shop)};`"></div>
                    </div>
                  </div>
                </td>
                <td>
                  <span :class="tierClass(shop.tier)" style="font-size:12px; font-weight:600;">
                    {{ tierLabel(shop.tier) }}
                  </span>
                </td>
                <td><span :class="statusClass(shop.status)">{{ statusLabel(shop.status) }}</span></td>
                <td style="font-size:12px;">{{ formatDate(shop.created_at) }}</td>
              </tr>
            </template>
            <tr v-else>
              <td colspan="8">
                <div class="empty-state">
                  <div class="empty-icon"><Store :size="24" color="var(--text-muted)" /></div>
                  <div style="font-weight:600; color:var(--text-secondary);">ບໍ່ພົບຮ້ານ</div>
                  <div style="font-size:12px;">ລອງປ່ຽນຕົວກອງ ຫຼື ຄຳຄົ້ນ</div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <div style="display:flex; align-items:center; justify-content:space-between; padding:14px 20px; border-top:1px solid var(--border);">
        <span style="font-size:12px; color:var(--text-muted);">ສະແດງ {{ shops.length }} ຈາກ {{ total }}</span>
        <div class="pagination">
          <button class="page-btn" :disabled="page <= 1" @click="loadShops(page - 1)"><ChevronLeft :size="14" /></button>
          <button v-for="p in visiblePages" :key="p" class="page-btn" :class="p === page && 'active'" @click="loadShops(p)">{{ p }}</button>
          <button class="page-btn" :disabled="page >= totalPages" @click="loadShops(page + 1)"><ChevronRight :size="14" /></button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Search, Download, ChevronLeft, ChevronRight, Store } from 'lucide-vue-next'
import { shopsApi } from '@/api/index.js'
import { formatCompact, formatDate, statusLabel, statusClass, tierLabel, tierClass } from '@/utils/format.js'

const router = useRouter()
const shops = ref([])
const total = ref(0)
const totalPages = ref(1)
const page = ref(1)
const loading = ref(true)
const search = ref('')
const filterProvince = ref('')
const filterStatus = ref('')
const filterTier = ref('')
const limit = 50
let searchTimer = null

const provinces = ['ວຽງຈັນ', 'ຫຼວງພະບາງ', 'ສະຫວັນນະເຂດ', 'ຈຳປາສັກ', 'ຄຳມ່ວນ', 'ຊຽງຂວາງ', 'ອຸດົມໄຊ', 'ຫຼວງນໍ້າທາ', 'ໂພນສາລີ', 'ບໍ່ແກ້ວ', 'ຜົ້ງສາລີ', 'ຫົວພັນ', 'ໄຊສົມບູນ', 'ບໍລິຄຳໄຊ', 'ຄຸ້ມ', 'ເຊກອງ', 'ອັດຕະປື', 'ໄຊຍະບູລີ', 'ນະຄອນ']

const visiblePages = computed(() => {
  const pages = []
  const start = Math.max(1, page.value - 2)
  const end = Math.min(totalPages.value, start + 4)
  for (let i = start; i <= end; i++) pages.push(i)
  return pages
})

async function loadShops(p = 1) {
  loading.value = true
  page.value = p
  try {
    const { data } = await shopsApi.list({ page: p, limit, search: search.value || undefined, province: filterProvince.value || undefined, status: filterStatus.value || undefined, tier: filterTier.value || undefined })
    shops.value = data.items
    total.value = data.total
    totalPages.value = data.pages
  } catch (e) { console.error(e) }
  finally { loading.value = false }
}

function onSearch() {
  clearTimeout(searchTimer)
  searchTimer = setTimeout(() => loadShops(1), 400)
}

function creditColor(shop) {
  const pct = shop.credit_limit ? shop.credit_used / shop.credit_limit : 0
  if (pct >= 0.9) return 'var(--danger)'
  if (pct >= 0.7) return 'var(--warning)'
  return 'var(--success)'
}

function exportExcel() {
  window.open('/api/reports/orders.xlsx', '_blank')
}

onMounted(() => loadShops())
</script>
