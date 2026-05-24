<template>
  <div ref="chartEl" :style="`width:100%; height:${height}px;`"></div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import * as echarts from 'echarts'

const props = defineProps({
  data: { type: Array, default: () => [] },
  height: { type: Number, default: 260 },
})

const chartEl = ref(null)
let chart = null

function buildOption() {
  const months = props.data.map(d => d.month)
  const revenue = props.data.map(d => d.revenue)
  const creditIssued = props.data.map(d => d.credit_issued)
  const profit = props.data.map(d => d.profit)

  return {
    backgroundColor: 'transparent',
    textStyle: { fontFamily: 'Noto Sans Lao, sans-serif' },
    grid: { top: 12, right: 16, bottom: 32, left: 72 },
    legend: { show: false },
    tooltip: {
      trigger: 'axis',
      backgroundColor: '#251812',
      borderColor: 'rgba(255,230,200,0.14)',
      textStyle: { color: '#FFFAF3', fontSize: 12 },
      formatter(params) {
        const fmt = v => Number(v).toLocaleString()
        let s = `<b>${params[0].name}</b><br/>`
        params.forEach(p => {
          const color = p.color?.colorStops?.[0]?.color || p.color
          s += `<span style="display:inline-block;width:8px;height:8px;border-radius:2px;background:${color};margin-right:5px;"></span>${p.seriesName}: <b>${fmt(p.value)}</b> ກີບ<br/>`
        })
        return s
      },
    },
    xAxis: {
      type: 'category',
      data: months,
      axisLabel: { color: 'rgba(255,250,243,0.5)', fontSize: 10 },
      axisLine: { lineStyle: { color: 'rgba(255,250,243,0.08)' } },
      splitLine: { show: false },
    },
    yAxis: [
      {
        type: 'value',
        axisLabel: {
          color: 'rgba(255,250,243,0.4)',
          fontSize: 10,
          formatter: v => v >= 1000000 ? `${(v / 1000000).toFixed(1)}M` : v >= 1000 ? `${(v / 1000).toFixed(0)}K` : v,
        },
        splitLine: { lineStyle: { color: 'rgba(255,250,243,0.05)' } },
        axisLine: { show: false },
      },
    ],
    series: [
      {
        name: 'ລາຍຮັບ',
        type: 'bar',
        barMaxWidth: 28,
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: '#6EE7A7' },
            { offset: 1, color: 'rgba(110,231,167,0.4)' },
          ]),
          borderRadius: [4, 4, 0, 0],
        },
        data: revenue,
      },
      {
        name: 'ສິນເຊື່ອອອກ',
        type: 'bar',
        barMaxWidth: 28,
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: '#E8854A' },
            { offset: 1, color: 'rgba(232,133,74,0.4)' },
          ]),
          borderRadius: [4, 4, 0, 0],
        },
        data: creditIssued,
      },
      {
        name: 'ກຳໄລ/ຂາດທຶນ',
        type: 'line',
        smooth: true,
        symbol: 'circle',
        symbolSize: 6,
        lineStyle: { color: '#FACC15', width: 2 },
        itemStyle: { color: '#FACC15' },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(250,204,21,0.15)' },
            { offset: 1, color: 'rgba(250,204,21,0)' },
          ]),
        },
        data: profit,
      },
    ],
  }
}

onMounted(() => {
  chart = echarts.init(chartEl.value, null, { renderer: 'svg' })
  chart.setOption(buildOption())
  window.addEventListener('resize', () => chart?.resize())
})

watch(() => props.data, () => chart?.setOption(buildOption(), true), { deep: true })
onUnmounted(() => { chart?.dispose(); chart = null })
</script>
