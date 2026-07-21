<template>
  <div style="position:relative;" ref="rootEl">
    <button type="button" class="input" style="display:flex; align-items:center; gap:8px; cursor:pointer; width:auto; min-width:220px;" @click="open = !open">
      <CalendarDays :size="15" color="var(--text-muted)" />
      <span style="flex:1; text-align:left;">{{ displayLabel }}</span>
      <ChevronDown :size="14" color="var(--text-muted)" />
    </button>

    <div v-if="open" class="card" style="position:absolute; top:calc(100% + 8px); left:0; z-index:200; width:300px; padding:16px; box-shadow:0 12px 32px rgba(42,32,21,0.18);">
      <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:12px;">
        <button type="button" class="page-btn" @click="prevMonth"><ChevronLeft :size="15" /></button>
        <span style="font-size:13px; font-weight:600; color:var(--text);">{{ monthNames[viewMonth] }} {{ viewYear }}</span>
        <button type="button" class="page-btn" @click="nextMonth"><ChevronRight :size="15" /></button>
      </div>

      <div style="display:grid; grid-template-columns:repeat(7, 1fr); gap:2px; margin-bottom:4px;">
        <span v-for="d in weekdays" :key="d" style="font-size:10px; color:var(--text-muted); text-align:center; font-weight:600;">{{ d }}</span>
      </div>

      <div style="display:grid; grid-template-columns:repeat(7, 1fr); gap:2px;">
        <button
          v-for="cell in dayCells"
          :key="cell.key"
          type="button"
          :disabled="!cell.inMonth"
          @click="selectDay(cell)"
          :style="cellStyle(cell)"
        >{{ cell.day }}</button>
      </div>

      <div style="font-size:11px; color:var(--text-muted); text-align:center; margin-top:10px;">
        {{ selectingEnd ? 'ກົດເລືອກວັນທີ່ສິ້ນສຸດ' : 'ກົດເລືອກວັນທີ່ເລີ່ມ' }}
      </div>

      <div style="display:flex; gap:8px; margin-top:14px;">
        <button type="button" class="btn btn-ghost btn-sm" style="flex:1; justify-content:center;" @click="clear">ລ້າງ</button>
        <button type="button" class="btn btn-primary btn-sm" style="flex:1; justify-content:center;" @click="confirm">ຢືນຢັນ</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { CalendarDays, ChevronDown, ChevronLeft, ChevronRight } from 'lucide-vue-next'

const props = defineProps({
  modelValue: { type: Object, default: () => ({ start: null, end: null }) },
})
const emit = defineEmits(['update:modelValue', 'confirm'])

const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
const weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']

const open = ref(false)
const rootEl = ref(null)
const today = new Date()
const viewMonth = ref(today.getMonth())
const viewYear = ref(today.getFullYear())

const tempStart = ref(props.modelValue.start ? new Date(props.modelValue.start) : null)
const tempEnd = ref(props.modelValue.end ? new Date(props.modelValue.end) : null)
const selectingEnd = ref(false)

watch(open, (v) => {
  if (v) {
    tempStart.value = props.modelValue.start ? new Date(props.modelValue.start) : null
    tempEnd.value = props.modelValue.end ? new Date(props.modelValue.end) : null
    selectingEnd.value = false
    if (tempStart.value) {
      viewMonth.value = tempStart.value.getMonth()
      viewYear.value = tempStart.value.getFullYear()
    }
  }
})

function toKey(d) { return d.toISOString().slice(0, 10) }
function sameDay(a, b) { return a && b && toKey(a) === toKey(b) }

const dayCells = computed(() => {
  const first = new Date(viewYear.value, viewMonth.value, 1)
  const startOffset = (first.getDay() + 6) % 7 // Monday-first
  const gridStart = new Date(viewYear.value, viewMonth.value, 1 - startOffset)
  const cells = []
  for (let i = 0; i < 42; i++) {
    const d = new Date(gridStart)
    d.setDate(gridStart.getDate() + i)
    cells.push({
      key: toKey(d),
      date: d,
      day: d.getDate(),
      inMonth: d.getMonth() === viewMonth.value,
    })
  }
  return cells
})

function cellStyle(cell) {
  const base = 'aspect-ratio:1; border:none; border-radius:8px; font-size:12px; cursor:pointer; background:transparent; color:var(--text);'
  if (!cell.inMonth) return base + 'visibility:hidden;'
  const isStart = sameDay(cell.date, tempStart.value)
  const isEnd = sameDay(cell.date, tempEnd.value)
  const inRange = tempStart.value && tempEnd.value && cell.date > tempStart.value && cell.date < tempEnd.value
  const isToday = sameDay(cell.date, today)
  if (isStart || isEnd) return base + `background:var(--primary); color:#FBF5E6; font-weight:700;`
  if (inRange) return base + `background:rgba(201,160,71,0.18); color:var(--text);`
  if (isToday) return base + `border:1px solid var(--primary); color:var(--text);`
  return base + 'color:var(--text-secondary);'
}

function selectDay(cell) {
  if (!cell.inMonth) return
  if (!selectingEnd.value) {
    tempStart.value = cell.date
    tempEnd.value = null
    selectingEnd.value = true
  } else {
    if (cell.date < tempStart.value) {
      tempEnd.value = tempStart.value
      tempStart.value = cell.date
    } else {
      tempEnd.value = cell.date
    }
    selectingEnd.value = false
  }
}

function prevMonth() {
  if (viewMonth.value === 0) { viewMonth.value = 11; viewYear.value-- } else { viewMonth.value-- }
}
function nextMonth() {
  if (viewMonth.value === 11) { viewMonth.value = 0; viewYear.value++ } else { viewMonth.value++ }
}

function clear() {
  tempStart.value = null
  tempEnd.value = null
  selectingEnd.value = false
  emit('update:modelValue', { start: null, end: null })
  emit('confirm', { start: null, end: null })
  open.value = false
}

function confirm() {
  const value = {
    start: tempStart.value ? toKey(tempStart.value) : null,
    end: tempEnd.value ? toKey(tempEnd.value) : (tempStart.value ? toKey(tempStart.value) : null),
  }
  emit('update:modelValue', value)
  emit('confirm', value)
  open.value = false
}

const displayLabel = computed(() => {
  if (!props.modelValue.start) return 'ເລືອກວັນທີ'
  const fmt = (s) => { const d = new Date(s); return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}` }
  if (!props.modelValue.end || props.modelValue.end === props.modelValue.start) return fmt(props.modelValue.start)
  return `${fmt(props.modelValue.start)} - ${fmt(props.modelValue.end)}`
})

function onClickOutside(e) {
  if (rootEl.value && !rootEl.value.contains(e.target)) open.value = false
}
onMounted(() => document.addEventListener('mousedown', onClickOutside))
onUnmounted(() => document.removeEventListener('mousedown', onClickOutside))
</script>
