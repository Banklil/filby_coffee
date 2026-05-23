<template>
  <div>
    <div style="margin-bottom:24px;">
      <h1 style="font-family:'Noto Serif Lao', serif; font-size:20px; font-weight:700; color:var(--cream);">ຕັ້ງຄ່າ</h1>
    </div>

    <div class="tab-nav">
      <button v-for="tab in tabs" :key="tab.key" class="tab-btn" :class="activeTab === tab.key && 'active'" @click="activeTab = tab.key">{{ tab.label }}</button>
    </div>

    <!-- Admins tab -->
    <div v-if="activeTab === 'admins'">
      <div style="display:flex; justify-content:flex-end; margin-bottom:12px;">
        <button class="btn btn-primary btn-sm" @click="openCreate"><Plus :size="13" /> ເພີ່ມ Admin</button>
      </div>
      <div class="card" style="padding:0; overflow:hidden;">
        <div class="table-wrapper">
          <table class="table">
            <thead><tr><th>ຊື່</th><th>ອີເມລ</th><th>Role</th><th>ສະຖານະ</th><th>Login ລ່າສຸດ</th><th></th></tr></thead>
            <tbody>
              <tr v-if="adminsLoading"><td colspan="6"><div class="skeleton" style="height:20px;"></div></td></tr>
              <tr v-for="a in admins" :key="a.id">
                <td style="font-weight:500; color:var(--text);">{{ a.name }}</td>
                <td>{{ a.email }}</td>
                <td><span class="badge" :class="roleClass(a.role)">{{ roleLabel(a.role) }}</span></td>
                <td><span :class="a.active ? 'badge badge-success' : 'badge badge-danger'">{{ a.active ? 'ເປີດ' : 'ປິດ' }}</span></td>
                <td style="font-size:12px;">{{ formatDate(a.last_login) }}</td>
                <td @click.stop>
                  <div style="display:flex; gap:6px;">
                    <button class="btn btn-ghost btn-sm" @click="openEdit(a)"><Pencil :size="12" /></button>
                    <button class="btn btn-danger btn-sm" @click="handleDelete(a)" v-if="a.id !== currentUserId"><Trash2 :size="12" /></button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Audit logs tab -->
    <div v-if="activeTab === 'audit'">
      <div class="card" style="padding:0; overflow:hidden;">
        <div class="table-wrapper">
          <table class="table">
            <thead><tr><th>Admin</th><th>Action</th><th>Entity</th><th>ID</th><th>ເວລາ</th></tr></thead>
            <tbody>
              <tr v-if="auditLoading"><td colspan="5"><div class="skeleton" style="height:20px;"></div></td></tr>
              <tr v-for="log in auditLogs" :key="log.id">
                <td>{{ log.admin_id }}</td>
                <td><span class="badge badge-muted" style="font-family:Manrope; font-size:10px;">{{ log.action }}</span></td>
                <td>{{ log.entity_type }}</td>
                <td class="num">{{ log.entity_id }}</td>
                <td style="font-size:12px;">{{ formatDateTime(log.created_at) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <!-- Admin form modal -->
  <div v-if="showFormModal" class="modal-overlay" @click.self="showFormModal = false">
    <div class="modal">
      <h3 style="font-size:15px; font-weight:700; margin-bottom:16px;">{{ editAdmin ? 'ແກ້ໄຂ Admin' : 'ເພີ່ມ Admin ໃໝ່' }}</h3>
      <div class="form-group">
        <label class="input-label">ຊື່</label>
        <input v-model="form.name" class="input" />
      </div>
      <div class="form-group">
        <label class="input-label">ອີເມລ</label>
        <input v-model="form.email" type="email" class="input" :disabled="!!editAdmin" />
      </div>
      <div class="form-group">
        <label class="input-label">Role</label>
        <select v-model="form.role" class="input">
          <option value="super_admin">Super Admin</option>
          <option value="manager">Manager</option>
          <option value="support">Support</option>
          <option value="accountant">Accountant</option>
        </select>
      </div>
      <div class="form-group">
        <label class="input-label">ລະຫັດຜ່ານ {{ editAdmin ? '(ເຫຼືອຫວ່າງໄວ້ຖ້າບໍ່ປ່ຽນ)' : '*' }}</label>
        <input v-model="form.password" type="password" class="input" />
      </div>
      <div style="display:flex; gap:10px; justify-content:flex-end;">
        <button class="btn btn-ghost" @click="showFormModal = false">ຍົກເລີກ</button>
        <button class="btn btn-primary" @click="handleSave">ບັນທຶກ</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { Plus, Pencil, Trash2 } from 'lucide-vue-next'
import { settingsApi } from '@/api/index.js'
import { useAuthStore } from '@/stores/auth.js'
import { useToastStore } from '@/stores/toast.js'
import { formatDate, formatDateTime } from '@/utils/format.js'

const authStore = useAuthStore()
const toast = useToastStore()
const activeTab = ref('admins')
const admins = ref([])
const adminsLoading = ref(true)
const auditLogs = ref([])
const auditLoading = ref(true)
const showFormModal = ref(false)
const editAdmin = ref(null)
const form = ref({ name: '', email: '', role: 'manager', password: '' })

const tabs = [
  { key: 'admins', label: 'ຈັດການ Admin' },
  { key: 'audit', label: 'Audit Log' },
]

const currentUserId = computed(() => authStore.user?.id)

function roleLabel(r) { return { super_admin: 'Super Admin', manager: 'Manager', support: 'Support', accountant: 'Accountant' }[r] || r }
function roleClass(r) { return { super_admin: 'badge-danger', manager: 'badge-warning', support: 'badge-info', accountant: 'badge-muted' }[r] || 'badge-muted' }

async function loadAdmins() {
  adminsLoading.value = true
  try {
    const { data } = await settingsApi.listAdmins()
    admins.value = data
  } catch { toast.error('ໂຫຼດ admin ບໍ່ສຳເລັດ (ຕ້ອງການ super_admin)') }
  finally { adminsLoading.value = false }
}

async function loadAuditLogs() {
  auditLoading.value = true
  try {
    const { data } = await settingsApi.auditLogs({ page: 1, limit: 50 })
    auditLogs.value = data.items
  } catch {}
  finally { auditLoading.value = false }
}

function openCreate() {
  editAdmin.value = null
  form.value = { name: '', email: '', role: 'manager', password: '' }
  showFormModal.value = true
}

function openEdit(a) {
  editAdmin.value = a
  form.value = { name: a.name, email: a.email, role: a.role, password: '' }
  showFormModal.value = true
}

async function handleSave() {
  try {
    if (editAdmin.value) {
      const d = { name: form.value.name, role: form.value.role }
      if (form.value.password) d.password = form.value.password
      await settingsApi.updateAdmin(editAdmin.value.id, d)
      toast.success('ແກ້ໄຂ Admin ສຳເລັດ')
    } else {
      await settingsApi.createAdmin(form.value)
      toast.success('ສ້າງ Admin ໃໝ່ສຳເລັດ')
    }
    showFormModal.value = false
    loadAdmins()
  } catch (e) { toast.error(e.response?.data?.detail || 'ເກີດຂໍ້ຜິດພາດ') }
}

async function handleDelete(a) {
  if (!confirm(`ລຶບ "${a.name}"?`)) return
  await settingsApi.deleteAdmin(a.id)
  toast.success('ລຶບ Admin ແລ້ວ')
  loadAdmins()
}

onMounted(() => { loadAdmins(); loadAuditLogs() })
</script>
