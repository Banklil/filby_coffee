<template>
  <div class="toast-container">
    <TransitionGroup name="toast">
      <div
        v-for="toast in toastStore.toasts"
        :key="toast.id"
        :class="`toast toast-${toast.type}`"
        @click="toastStore.remove(toast.id)"
      >
        <CheckCircle v-if="toast.type === 'success'" :size="16" />
        <XCircle v-else-if="toast.type === 'error'" :size="16" />
        <Info v-else :size="16" />
        <span>{{ toast.message }}</span>
      </div>
    </TransitionGroup>
  </div>
</template>

<script setup>
import { CheckCircle, XCircle, Info } from 'lucide-vue-next'
import { useToastStore } from '@/stores/toast.js'
const toastStore = useToastStore()
</script>

<style scoped>
.toast-enter-active, .toast-leave-active { transition: all 0.3s ease; }
.toast-enter-from { opacity: 0; transform: translateX(20px); }
.toast-leave-to { opacity: 0; transform: translateX(20px); }
</style>
