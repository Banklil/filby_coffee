<template>
  <div class="kpi-card">
    <div style="display:flex; align-items:flex-start; justify-content:space-between; margin-bottom:12px;">
      <div style="font-size:12px; color:var(--text-muted); font-weight:500;">{{ label }}</div>
      <div :style="`background:${iconBg}; border-radius:8px; padding:8px; display:flex;`">
        <component :is="icon" :size="16" :color="iconColor" />
      </div>
    </div>

    <template v-if="loading">
      <div class="skeleton" style="height:28px; width:60%; margin-bottom:8px;"></div>
      <div class="skeleton" style="height:14px; width:40%;"></div>
    </template>
    <template v-else>
      <div style="font-size:26px; font-weight:700; color:var(--text); line-height:1.2; font-family:'Noto Serif Lao', 'Noto Sans Lao', serif;">{{ value }}</div>
      <div v-if="sub" style="display:flex; align-items:center; gap:6px; margin-top:6px;">
        <span :class="changeClass" style="font-size:12px; font-weight:600; display:flex; align-items:center; gap:2px;">
          <TrendingUp v-if="changePositive" :size="12" />
          <TrendingDown v-else-if="changeNegative" :size="12" />
          {{ sub }}
        </span>
      </div>
      <div v-if="subLabel" style="font-size:11px; color:var(--text-muted); margin-top:2px;">{{ subLabel }}</div>
    </template>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { TrendingUp, TrendingDown } from 'lucide-vue-next'

const props = defineProps({
  label: String,
  value: [String, Number],
  sub: String,
  subLabel: String,
  icon: Object,
  iconBg: { default: 'rgba(232,133,74,0.12)' },
  iconColor: { default: 'var(--primary)' },
  loading: Boolean,
  trend: { type: Number, default: null },
})

const changePositive = computed(() => props.trend > 0)
const changeNegative = computed(() => props.trend < 0)
const changeClass = computed(() => {
  if (props.trend > 0) return 'kpi-change-up'
  if (props.trend < 0) return 'kpi-change-down'
  return 'kpi-change-neutral'
})
</script>

<style scoped>
.kpi-change-up { color: var(--success); }
.kpi-change-down { color: var(--danger); }
.kpi-change-neutral { color: var(--text-muted); }
</style>
