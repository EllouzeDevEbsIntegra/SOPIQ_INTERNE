import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { add, mul, pct, round, sub } from '../utils/money'

/**
 * Current order lives entirely in the browser (instant taps); the backend re-prices and validates at checkout.
 * Line shape: { key, productId, product, quantity, unitPrice, modifiers:[{id,name,priceDelta}], components:[{productId, product, quantity, modifiers, priceDelta}], discountPercent, discountAmount, note }
 */
let keySeq = 0
function uuid() { return (crypto.randomUUID ? crypto.randomUUID() : 'ref-' + Date.now() + '-' + Math.random().toString(16).slice(2)) }

export const useCartStore = defineStore('cart', () => {
  const lines = ref([])
  const serviceMode = ref('TAKEAWAY')
  const customer = ref({ id: null, name: '', phone: '' })
  const note = ref('')
  const discountPercent = ref(0)
  const discountAmount = ref(0)
  const heldOrderId = ref(null)
  const heldRef = ref(null)
  const clientRef = ref(uuid())
  const selectedKey = ref(null)

  function lineUnit(l) {
    const mods = (l.modifiers || []).reduce((s, m) => add(s, m.priceDelta), 0)
    const comps = (l.components || []).reduce((s, c) => add(s, mul(add(c.priceDelta || 0, (c.modifiers || []).reduce((a, m) => add(a, m.priceDelta), 0)), c.quantity || 1)), 0)
    return add(add(l.unitPrice, mods), comps)
  }
  function lineGross(l) { return mul(lineUnit(l), l.quantity) }
  function lineDiscount(l) { const g = lineGross(l); if (l.discountAmount > 0) return Math.min(l.discountAmount, g); return pct(g, l.discountPercent) }
  function lineTotal(l) { return sub(lineGross(l), lineDiscount(l)) }

  const subtotal = computed(() => lines.value.reduce((s, l) => add(s, lineGross(l)), 0))
  const lineDiscountTotal = computed(() => lines.value.reduce((s, l) => add(s, lineDiscount(l)), 0))
  const afterLines = computed(() => sub(subtotal.value, lineDiscountTotal.value))
  const orderDiscount = computed(() => discountAmount.value > 0 ? Math.min(discountAmount.value, afterLines.value) : pct(afterLines.value, discountPercent.value))
  const total = computed(() => round(sub(afterLines.value, orderDiscount.value)))
  const itemCount = computed(() => lines.value.reduce((s, l) => s + Number(l.quantity), 0))
  const isEmpty = computed(() => lines.value.length === 0)

  function sameConfig(a, b) {
    const ids = (x) => (x.modifiers || []).map(m => m.id).sort().join(',')
    const comps = (x) => (x.components || []).map(c => c.productId + ':' + (c.quantity || 1) + ':' + ids(c)).sort().join('|')
    return a.productId === b.productId && ids(a) === ids(b) && comps(a) === comps(b) && (a.note || '') === (b.note || '') && a.unitPrice === b.unitPrice && !a.discountPercent && !a.discountAmount
  }
  function addLine({ product, quantity = 1, modifiers = [], components = [], note = '' }) {
    const candidate = { productId: product.id, product, quantity, unitPrice: Number(product.price), modifiers, components, note, discountPercent: 0, discountAmount: 0 }
    const existing = lines.value.find(l => sameConfig(l, candidate))
    if (existing) { existing.quantity = add(existing.quantity, quantity); selectedKey.value = existing.key; return existing }
    candidate.key = ++keySeq
    lines.value.push(candidate)
    selectedKey.value = candidate.key
    return candidate
  }
  function find(key) { return lines.value.find(l => l.key === key) }
  function setQuantity(key, q) { const l = find(key); if (!l) return; if (q <= 0) remove(key); else l.quantity = q }
  function increment(key, d = 1) { const l = find(key); if (l) setQuantity(key, add(l.quantity, d)) }
  function remove(key) { lines.value = lines.value.filter(l => l.key !== key); if (selectedKey.value === key) selectedKey.value = lines.value.length ? lines.value[lines.value.length - 1].key : null }
  function setLineDiscount(key, percent, amount) { const l = find(key); if (l) { l.discountPercent = percent || 0; l.discountAmount = amount || 0 } }
  function setLinePrice(key, price) { const l = find(key); if (l) l.unitPrice = round(price) }
  function setLineNote(key, n) { const l = find(key); if (l) l.note = n }
  function setLineModifiers(key, mods) { const l = find(key); if (l) l.modifiers = mods }
  function setOrderDiscount(percent, amount) { discountPercent.value = percent || 0; discountAmount.value = amount || 0 }
  function clear() {
    lines.value = []; customer.value = { id: null, name: '', phone: '' }; note.value = ''; discountPercent.value = 0; discountAmount.value = 0
    heldOrderId.value = null; heldRef.value = null; clientRef.value = uuid(); selectedKey.value = null
  }
  function toRequest(registerId) {
    return {
      clientRef: clientRef.value, registerId, serviceMode: serviceMode.value, customerId: customer.value.id || null,
      customerName: customer.value.name || null, customerPhone: customer.value.phone || null, note: note.value || null,
      discountPercent: discountPercent.value || 0, discountAmount: discountAmount.value || 0, heldOrderId: heldOrderId.value,
      lines: lines.value.map(l => ({
        productId: l.productId, quantity: l.quantity, unitPrice: l.unitPrice, discountPercent: l.discountPercent || 0, discountAmount: l.discountAmount || 0,
        note: l.note || null, modifierIds: (l.modifiers || []).map(m => m.id),
        components: (l.components || []).map(c => ({ productId: c.productId, quantity: c.quantity || 1, modifierIds: (c.modifiers || []).map(m => m.id), note: c.note || null }))
      }))
    }
  }
  /** Rebuild the cart from a held order (OrderDto). */
  function loadFromOrder(order, productsById) {
    clear()
    heldOrderId.value = order.id; heldRef.value = order.heldRef
    serviceMode.value = order.serviceMode || serviceMode.value
    customer.value = { id: order.customerId || null, name: order.customerName || '', phone: order.customerPhone || '' }
    note.value = order.note || ''
    discountPercent.value = Number(order.discountPercent) || 0; discountAmount.value = Number(order.discountAmount) || 0
    for (const ol of order.lines) {
      const product = productsById[ol.productId]
      if (!product) continue
      const modifiers = (ol.modifiers || []).map(m => ({ id: m.modifierId, name: m.name, priceDelta: Number(m.priceDelta) }))
      const components = (ol.components || []).map(c => ({ productId: c.productId, product: productsById[c.productId], quantity: Number(c.quantity), priceDelta: Number(c.unitPrice), modifiers: (c.modifiers || []).map(m => ({ id: m.modifierId, name: m.name, priceDelta: Number(m.priceDelta) })) }))
      const l = { key: ++keySeq, productId: ol.productId, product, quantity: Number(ol.quantity), unitPrice: Number(ol.unitPrice), modifiers, components, note: ol.note || '', discountPercent: Number(ol.discountPercent) || 0, discountAmount: Number(ol.discountAmount) || 0 }
      lines.value.push(l)
    }
  }
  return { lines, serviceMode, customer, note, discountPercent, discountAmount, heldOrderId, heldRef, clientRef, selectedKey,
    subtotal, lineDiscountTotal, orderDiscount, total, itemCount, isEmpty, lineUnit, lineGross, lineDiscount, lineTotal,
    addLine, find, setQuantity, increment, remove, setLineDiscount, setLinePrice, setLineNote, setLineModifiers, setOrderDiscount, clear, toRequest, loadFromOrder }
})
