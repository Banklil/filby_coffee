<template>
  <div ref="chartEl" :style="`width:100%; height:${height}px;`"></div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import * as echarts from 'echarts'

const props = defineProps({
  data: { type: Array, default: () => [] },
  height: { type: Number, default: 220 },
  color: { type: String, default: '#E8854A' },
  labelKey: { type: String, default: 'name' },
  valueKey: { type: String, default: 'credit_used' },
  horizontal: { type: Boolean, default: true },
})

const chartEl = ref(null)
let chart = null

function buildOption() {
  const labels = props.data.map(d => d[props.labelKey])
  const values = props.data.map(d => d[props.valueKey])
  const isH = props.horizontal
  return {
    backgroundColor: 'transparent',
    textStyle: { fontFamily: 'Noto Sans Lao, sans-serif' },
    grid: { top: 10, right: 20, bottom: isH ? 10 : 30, left: isH ? 120 : 50 },
    [isH ? 'xAxis' : 'yAxis']: { type: 'value', axisLabel: { color: 'rgba(255,250,243,0.4)', fontSize: 10, formatter: v => v >= 1000000 ? `${(v/1000000).toFixed(0)}M` : v }, splitLine: { lineStyle: { color: 'rgba(255,250,243,0.05)' } }, axisLine: { show: false } },
    [isH ? 'yAxis' : 'xAxis']: { type: 'category', data: labels, axisLabel: { color: 'rgba(255,250,243,0.55)', fontSize: 11 }, axisLine: { lineStyle: { color: 'rgba(255,250,243,0.08)' } }, splitLine: { show: false } },
    series: [{ type: 'bar', data: values, itemStyle: { color: props.color, borderRadius: [0, 4, 4, 0] }, barMaxWidth: 20 }],
    tooltip: { trigger: 'axis', backgroundColor: '#251812', borderColor: 'rgba(255,230,200,0.14)', textStyle: { color: '#FFFAF3', fontSize: 12 }, formatter: params => `${params[0].name}<br/><b>${Number(params[0].value).toLocaleString()}</b>` },
  }
}

onMounted(() => {
  chart = echarts.init(chartEl.value, null, { renderer: 'svg' })
  chart.setOption(buildOption())
  window.addEventListener('resize', () => chart?.resize())
})

watch(() => props.data, () => chart?.setOption(buildOption()), { deep: true })
onUnmounted(() => { chart?.dispose(); chart = null })
</script>
