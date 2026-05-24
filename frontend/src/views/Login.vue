<template>
  <div style="min-height:100vh; display:flex; align-items:center; justify-content:center; background: radial-gradient(ellipse at 20% 50%, rgba(232,133,74,0.08) 0%, transparent 60%), var(--bg-deep); padding:20px;">
    <div style="width:100%; max-width:400px;">
      <!-- Logo -->
      <div style="text-align:center; margin-bottom:40px;">
        <div style="width:60px; height:60px; background:linear-gradient(135deg, var(--primary), var(--primary-deep)); border-radius:18px; display:flex; align-items:center; justify-content:center; margin:0 auto 16px;">
          <Coffee :size="28" color="#fff" />
        </div>
        <h1 style=" font-size:22px; font-weight:700; color:var(--cream);">Filby Coffee</h1>
        <p style="color:var(--text-muted); font-size:13px; margin-top:4px;">Admin Dashboard</p>
      </div>

      <!-- Form -->
      <div class="card" style="padding:28px;">
        <h2 style="font-size:16px; font-weight:600; margin-bottom:24px; color:var(--text);">ເຂົ້າສູ່ລະບົບ</h2>

        <form @submit.prevent="handleLogin">
          <div class="form-group">
            <label class="input-label">ອີເມລ</label>
            <input v-model="email" type="email" class="input" placeholder="admin@filby.la" required :disabled="loading" />
          </div>

          <div class="form-group">
            <label class="input-label">ລະຫັດຜ່ານ</label>
            <div style="position:relative;">
              <input v-model="password" :type="showPassword ? 'text' : 'password'" class="input" placeholder="••••••••" required :disabled="loading" style="padding-right:40px;" />
              <button type="button" @click="showPassword = !showPassword" style="position:absolute; right:12px; top:50%; transform:translateY(-50%); background:none; border:none; cursor:pointer; color:var(--text-muted); padding:2px;">
                <Eye v-if="!showPassword" :size="15" />
                <EyeOff v-else :size="15" />
              </button>
            </div>
          </div>

          <div v-if="authStore.error" style="background:rgba(248,113,113,0.1); border:1px solid rgba(248,113,113,0.3); border-radius:8px; padding:10px 12px; font-size:13px; color:var(--danger); margin-bottom:16px;">
            {{ authStore.error }}
          </div>

          <button type="submit" class="btn btn-primary" style="width:100%; justify-content:center; padding:12px;" :disabled="loading">
            <Loader2 v-if="loading" :size="15" class="animate-spin" />
            <span>{{ loading ? 'ກຳລັງເຂົ້າລະບົບ...' : 'ເຂົ້າສູ່ລະບົບ' }}</span>
          </button>
        </form>

      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { Coffee, Eye, EyeOff, Loader2 } from 'lucide-vue-next'
import { useAuthStore } from '@/stores/auth.js'

const authStore = useAuthStore()
const router = useRouter()
const email = ref('')
const password = ref('')
const showPassword = ref(false)
const loading = ref(false)

async function handleLogin() {
  loading.value = true
  const ok = await authStore.login(email.value, password.value)
  loading.value = false
  if (ok) router.push('/dashboard')
}
</script>

<style scoped>
.animate-spin { animation: spin 1s linear infinite; }
@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
</style>
