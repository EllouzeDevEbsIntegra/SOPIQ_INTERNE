// Money helpers — TND with 3 decimals ("8,500 DT"). All arithmetic on integers (millimes) to avoid float drift.
let DECIMALS = 3
let SYMBOL = 'DT'
export function configureMoney({ decimals, symbol } = {}) {
  if (decimals !== undefined && decimals !== null) DECIMALS = Number(decimals)
  if (symbol) SYMBOL = symbol
}
export const decimals = () => DECIMALS
export const symbol = () => SYMBOL
export function round(v) { const f = 10 ** DECIMALS; return Math.round((Number(v) || 0) * f + Number.EPSILON) / f }
export function add(a, b) { return round((Number(a) || 0) + (Number(b) || 0)) }
export function sub(a, b) { return round((Number(a) || 0) - (Number(b) || 0)) }
export function mul(a, b) { return round((Number(a) || 0) * (Number(b) || 0)) }
export function pct(base, percent) { return round((Number(base) || 0) * (Number(percent) || 0) / 100) }
export function fmt(v, withSymbol = false) {
  const n = Number(v) || 0
  const s = n.toLocaleString('fr-FR', { minimumFractionDigits: DECIMALS, maximumFractionDigits: DECIMALS }).replace(/ /g, ' ')
  return withSymbol ? `${s} ${SYMBOL}` : s
}
export function fmtQty(q) { const n = Number(q) || 0; return Number.isInteger(n) ? String(n) : n.toLocaleString('fr-FR', { maximumFractionDigits: 3 }) }
export function parseAmount(s) { if (s === null || s === undefined || s === '') return 0; return round(String(s).replace(/\s/g, '').replace(',', '.')) }
