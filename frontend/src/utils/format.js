export function formatCurrency(amount) {
  if (amount == null) return '0 ກີບ'
  return `${Number(amount).toLocaleString('en-US')} ກີບ`
}

export function formatNumber(n) {
  if (n == null) return '0'
  return Number(n).toLocaleString('en-US')
}

export function formatDate(dateStr) {
  if (!dateStr) return '-'
  const d = new Date(dateStr)
  const day = String(d.getDate()).padStart(2, '0')
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const year = d.getFullYear()
  return `${day}/${month}/${year}`
}

export function formatDateTime(dateStr) {
  if (!dateStr) return '-'
  const d = new Date(dateStr)
  const day = String(d.getDate()).padStart(2, '0')
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const year = d.getFullYear()
  const h = String(d.getHours()).padStart(2, '0')
  const m = String(d.getMinutes()).padStart(2, '0')
  return `${day}/${month}/${year} ${h}:${m}`
}

export function formatCompact(amount) {
  if (!amount) return '0'
  if (amount >= 1_000_000_000) return `${(amount / 1_000_000_000).toFixed(1)}B`
  if (amount >= 1_000_000) return `${(amount / 1_000_000).toFixed(1)}M`
  if (amount >= 1_000) return `${(amount / 1_000).toFixed(0)}K`
  return String(amount)
}

export function statusLabel(status) {
  const map = {
    active: 'ເປີດໃຊ້ງານ', suspended: 'ຖືກ Suspend', pending: 'ລໍຖ້າ',
    approved: 'ອະນຸມັດ', rejected: 'ປະຕິເສດ',
    confirmed: 'ຢືນຢັນ', shipping: 'ກຳລັງສົ່ງ', delivered: 'ສົ່ງແລ້ວ', cancelled: 'ຍົກເລີກ',
  }
  return map[status] || status
}

export function statusClass(status) {
  const map = {
    active: 'badge-success', approved: 'badge-success', delivered: 'badge-success',
    suspended: 'badge-danger', rejected: 'badge-danger', cancelled: 'badge-danger',
    pending: 'badge-warning',
    confirmed: 'badge-info', shipping: 'badge-info',
  }
  return `badge ${map[status] || 'badge-muted'}`
}

export function tierLabel(tier) {
  return { gold: 'ທອງ', silver: 'ເງິນ', bronze: 'ທອງແດງ' }[tier] || tier
}

export function tierClass(tier) {
  return { gold: 'tier-gold', silver: 'tier-silver', bronze: 'tier-bronze' }[tier] || ''
}
