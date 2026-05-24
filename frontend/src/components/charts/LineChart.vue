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
  label: { type: String, default: 'ຈຳນວນ' },
})

const chartEl = ref(null)
let chart = null

function buildOption() {
  return {
    backgroundColor: 'transparent',
    grid: { top: 10, right: 10, bottom: 30, left: 50 },
    textStyle: { fontFamily: 'Noto Sans Lao, sans-serif' },
    xAxis: {
      type: 'category',
      data: props.data.map(d => d.date),
      axisLine: { lineStyle: { color: 'rgba(255,250,243,0.08)' } },
      axisLabel: { color: 'rgba(255,250,243,0.4)', fontSize: 10, fontFamily: 'Noto Sans Lao, sans-serif', interval: Math.floor(props.data.length / 6) },
      splitLine: { show: false },
    },
    yAxis: {
      type: 'value',
      axisLabel: { color: 'rgba(255,250,243,0.4)', fontSize: 10, fontFamily: 'Noto Sans Lao, sans-serif', formatter: v => v >= 1000000 ? `${(v/1000000).toFixed(0)}M` : v >= 1000 ? `${(v/1000).toFixed(0)}K` : v },
      splitLine: { lineStyle: { color: 'rgba(255,250,243,0.05)' } },
      axisLine: { show: false },
    },
    series: [{
      name: props.label,
      type: 'line',
      data: props.data.map(d => d.amount),
      smooth: true,
      symbol: 'none',
      lineStyle: { color: props.color, width: 2 },
      areaStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [{ offset: 0, color: props.color + '40' }, { offset: 1, color: props.color + '00' }] } },
    }],
    tooltip: { trigger: 'axis', backgroundColor: '#251812', borderColor: 'rgba(255,230,200,0.14)', textStyle: { color: '#FFFAF3', fontSize: 12 }, formatter: params => `${params[0].name}<br/><b>${Number(params[0].value).toLocaleString()} ກີບ</b>` },
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
