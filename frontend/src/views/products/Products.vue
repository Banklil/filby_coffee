<template>
  <div>
    <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:24px;">
      <div>
        <h1 style="font-family:'Noto Serif Lao', serif; font-size:20px; font-weight:700; color:var(--cream);">ສິນຄ້າ</h1>
        <p style="font-size:13px; color:var(--text-muted);">ຈັດການເມັດກາເຟ ແລະ ອຸປະກອນ</p>
      </div>
      <button class="btn btn-primary" @click="openCreate"><Plus :size="14" /> ເພີ່ມສິນຄ້າ</button>
    </div>

    <!-- Category tabs -->
    <div class="tab-nav" style="margin-bottom:0;">
      <button v-for="cat in categories" :key="cat.key" class="tab-btn" :class="filterCat === cat.key && 'active'" @click="filterCat = cat.key">{{ cat.label }}</button>
    </div>

    <div style="display:grid; grid-template-columns:repeat(auto-fill, minmax(240px, 1fr)); gap:16px; margin-top:0; padding:0;" class="card" style="padding:16px;">
      <template v-if="loading">
        <div v-for="i in 6" :key="i" class="skeleton" style="height:180px; border-radius:10px;"></div>
      </template>
      <template v-else-if="filteredProducts.length">
        <div v-for="p in filteredProducts" :key="p.id" style="background:var(--surface-2); border:1px solid var(--border); border-radius:10px; overflow:hidden; transition:border-color 0.2s;" class="product-card">
          <div style="height:100px; background:var(--surface-3); display:flex; align-items:center; justify-content:center; position:relative;">
            <img v-if="p.image_url" :src="p.image_url" style="width:100%; height:100%; object-fit:cover;" />
            <Package v-else :size="32" color="var(--text-muted)" />
            <span v-if="!p.active" style="position:absolute; top:6px; right:6px; background:rgba(248,113,113,0.9); color:#fff; font-size:10px; padding:2px 6px; border-radius:4px;">ປິດ</span>
          </div>
          <div style="padding:12px;">
            <div style="font-size:13px; font-weight:600; color:var(--text); margin-bottom:4px;">{{ p.name }}</div>
            <div style="font-size:11px; color:var(--text-muted); margin-bottom:8px;">{{ p.origin || catLabel(p.category) }} · {{ p.unit }}</div>
            <div class="num" style="font-size:16px; font-weight:700; color:var(--primary);">{{ formatCurrency(p.price) }}</div>
            <div style="font-size:11px; color:var(--text-muted); margin-top:2px;">ສະຕັອກ: <span class="num">{{ p.stock_qty }}</span> {{ p.unit }}</div>
            <div style="display:flex; gap:6px; margin-top:10px;">
              <button class="btn btn-ghost btn-sm" @click="openEdit(p)" style="flex:1; justify-content:center; font-size:11px;"><Pencil :size="11" /> ແກ້ໄຂ</button>
              <button class="btn btn-ghost btn-sm" @click="openStock(p)" style="font-size:11px;"><Package :size="11" /></button>
              <button class="btn btn-danger btn-sm" @click="handleDelete(p)" style="font-size:11px;"><Trash2 :size="11" /></button>
            </div>
          </div>
        </div>
      </template>
      <div v-else style="grid-column:1/-1;">
        <div class="empty-state">
          <div class="empty-icon"><Package :size="24" color="var(--text-muted)" /></div>
          <div style="font-weight:600; color:var(--text-secondary);">ບໍ່ມີສິນຄ້າ</div>
        </div>
      </div>
    </div>
  </div>

  <!-- Create/Edit Modal -->
  <div v-if="showFormModal" class="modal-overlay" @click.self="showFormModal = false">
    <div class="modal" style="max-width:520px;">
      <h3 style="font-size:15px; font-weight:700; margin-bottom:16px;">{{ editProduct ? 'ແກ້ໄຂສິນຄ້າ' : 'ເພີ່ມສິນຄ້າໃໝ່' }}</h3>
      <div class="form-row">
        <div class="form-group">
          <label class="input-label">ຊື່ສິນຄ້າ *</label>
          <input v-model="form.name" class="input" required />
        </div>
        <div class="form-group">
          <label class="input-label">ໝວດ *</label>
          <select v-model="form.category" class="input">
            <option v-for="c in categories.slice(1)" :key="c.key" :value="c.key">{{ c.label }}</option>
          </select>
        </div>
        <div class="form-group">
          <label class="input-label">ແຫຼ່ງທີ່ມາ</label>
          <input v-model="form.origin" class="input" placeholder="ໂບລາເວັນ, ປາກຊອງ..." />
        </div>
        <div class="form-group">
          <label class="input-label">ລາຄາ (ກີບ) *</label>
          <input v-model.number="form.price" type="number" class="input" />
        </div>
        <div class="form-group">
          <label class="input-label">ໜ່ວຍ</label>
          <input v-model="form.unit" class="input" placeholder="kg, ອັນ, ກ່ອງ..." />
        </div>
        <div class="form-group" v-if="!editProduct">
          <label class="input-label">ສະຕັອກເລີ່ມຕົ້ນ</label>
          <input v-model.number="form.stock_qty" type="number" class="input" />
        </div>
      </div>
      <div class="form-group" v-if="!editProduct">
        <label class="input-label">ຮູບ (ບໍ່ບັງຄັບ)</label>
        <input type="file" accept="image/*" @change="onFileChange" class="input" style="padding:6px;" />
      </div>
      <div style="display:flex; gap:10px; justify-content:flex-end; margin-top:8px;">
        <button class="btn btn-ghost" @click="showFormModal = false">ຍົກເລີກ</button>
        <button class="btn btn-primary" @click="handleSave" :disabled="saveLoading">{{ saveLoading ? 'ກຳລັງບັນທຶກ...' : 'ບັນທຶກ' }}</button>
      </div>
    </div>
  </div>

  <!-- Stock modal -->
  <div v-if="showStockModal" class="modal-overlay" @click.self="showStockModal = false">
    <div class="modal">
      <h3 style="font-size:15px; font-weight:700; margin-bottom:16px;">ອັບເດດສະຕັອກ — {{ stockProduct?.name }}</h3>
      <div class="form-group">
        <label class="input-label">ຕື່ມ / ຫຼຸດ ສະຕັອກ (+/-)</label>
        <input v-model.number="stockDelta" type="number" class="input" />
      </div>
      <div class="form-group">
        <label class="input-label">ເຫດຜົນ</label>
        <input v-model="stockReason" class="input" />
      </div>
      <div style="display:flex; gap:10px; justify-content:flex-end;">
        <button class="btn btn-ghost" @click="showStockModal = false">ຍົກເລີກ</button>
        <button class="btn btn-primary" @click="handleStockUpdate">ບັນທຶກ</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Plus, Pencil, Trash2, Package } from 'lucide-vue-next'
import { productsApi } from '@/api/index.js'
import { useToastStore } from '@/stores/toast.js'
import { formatCurrency } from '@/utils/format.js'

const toast = useToastStore()
const products = ref([])
const loading = ref(true)
const filterCat = ref('all')
const showFormModal = ref(false)
const editProduct = ref(null)
const saveLoading = ref(false)
const showStockModal = ref(false)
const stockProduct = ref(null)
const stockDelta = ref(0)
const stockReason = ref('')
const imageFile = ref(null)
const form = ref({ name: '', category: 'arabica', price: 0, origin: '', unit: 'kg', stock_qty: 0 })

const categories = [
  { key: 'all', label: 'ທັງໝົດ' },
  { key: 'arabica', label: 'Arabica' },
  { key: 'robusta', label: 'Robusta' },
  { key: 'special', label: 'Special' },
  { key: 'equipment', label: 'ອຸປະກອນ' },
]

function catLabel(k) {
  return categories.find(c => c.key === k)?.label || k
}

const filteredProducts = computed(() => {
  if (filterCat.value === 'all') return products.value
  return products.value.filter(p => p.category === filterCat.value)
})

async function loadProducts() {
  loading.value = true
  const { data } = await productsApi.list()
  products.value = data
  loading.value = false
}

function openCreate() {
  editProduct.value = null
  form.value = { name: '', category: 'arabica', price: 0, origin: '', unit: 'kg', stock_qty: 0 }
  imageFile.value = null
  showFormModal.value = true
}

function openEdit(p) {
  editProduct.value = p
  form.value = { name: p.name, category: p.category, price: p.price, origin: p.origin, unit: p.unit }
  showFormModal.value = true
}

function openStock(p) {
  stockProduct.value = p
  stockDelta.value = 0
  stockReason.value = ''
  showStockModal.value = true
}

function onFileChange(e) {
  imageFile.value = e.target.files[0]
}

async function handleSave() {
  saveLoading.value = true
  try {
    if (editProduct.value) {
      await productsApi.update(editProduct.value.id, form.value)
      toast.success('ແກ້ໄຂສິນຄ້າສຳເລັດ')
    } else {
      const fd = new FormData()
      Object.entries(form.value).forEach(([k, v]) => fd.append(k, v))
      if (imageFile.value) fd.append('image', imageFile.value)
      await productsApi.create(fd)
      toast.success('ເພີ່ມສິນຄ້າສຳເລັດ')
    }
    showFormModal.value = false
    loadProducts()
  } catch (e) { toast.error(e.response?.data?.detail || 'ເກີດຂໍ້ຜິດພາດ') }
  finally { saveLoading.value = false }
}

async function handleStockUpdate() {
  await productsApi.updateStock(stockProduct.value.id, { delta: stockDelta.value, reason: stockReason.value })
  showStockModal.value = false
  toast.success('ອັບເດດສະຕັອກສຳເລັດ')
  loadProducts()
}

async function handleDelete(p) {
  if (!confirm(`ລຶບ "${p.name}"?`)) return
  await productsApi.delete(p.id)
  toast.success('ລຶບສິນຄ້າສຳເລັດ')
  loadProducts()
}

onMounted(loadProducts)
</script>

<style scoped>
.product-card:hover { border-color: var(--border-strong); }
</style>
