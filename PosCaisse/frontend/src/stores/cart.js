import { defineStore } from 'pinia'
import { computed, ref, watch } from 'vue'
import { add, mul, pct, round, sub } from '../utils/money'

/**
 * Current order lives entirely in the browser (instant taps); the backend re-prices and validates at checkout.
 * Line shape: { key, productId, product, quantity, unitPrice, modifiers:[{id,name,priceDelta,quantity}], components:[{productId, product, quantity, modifiers, priceDelta}], discountPercent, discountAmount, note }
 */
let keySeq = 0
function uuid() { return (crypto.randomUUID ? crypto.randomUUID() : 'ref-' + Date.now() + '-' + Math.random().toString(16).slice(2)) }

/* Le contrat de l'API reste une simple liste d'identifiants : une option ajoutee
   trois fois y figure trois fois, et le serveur regroupe en quantite. */
function expandModifiers(list) {
  const out = []
  for (const m of list || []) for (let i = 0; i < (m.quantity || 1); i++) out.push(m.id)
  return out
}

export const useCartStore = defineStore('cart', () => {
  const lines = ref([])
  const serviceMode = ref('TAKEAWAY')
  const customer = ref({ id: null, name: '', phone: '' })
  const courier = ref({ id: null, name: '', phone: '' })
  const note = ref('')
  const discountPercent = ref(0)
  const discountAmount = ref(0)
  const heldOrderId = ref(null)
  const heldRef = ref(null)
  const clientRef = ref(uuid())
  const selectedKey = ref(null)

  function lineUnit(l) {
    const mods = (l.modifiers || []).reduce((s, m) => add(s, mul(m.priceDelta, m.quantity || 1)), 0)
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

  /* Regle de gestion du destinataire :
       sur place  -> ni client ni livreur ;
       a emporter -> un client possible, jamais de livreur ;
       livraison  -> un livreur obligatoire, et un client si on le connait.
     Le changement de mode remet donc a zero ce qui n'a plus lieu d'etre, pour que
     l'ecran ne montre jamais un destinataire que le serveur refusera. */
  const noParty = () => ({ id: null, name: '', phone: '' })
  const canPickCustomer = computed(() => serviceMode.value !== 'DINE_IN')
  const canPickCourier = computed(() => serviceMode.value === 'DELIVERY')
  const needsCourier = computed(() => canPickCourier.value && !courier.value.id)
  watch(serviceMode, () => {
    if (!canPickCustomer.value) customer.value = noParty()
    if (!canPickCourier.value) courier.value = noParty()
  })

  function sameConfig(a, b) {
    const ids = (x) => (x.modifiers || []).map(m => m.id + '×' + (m.quantity || 1)).sort().join(',')
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
    lines.value = []; customer.value = noParty(); courier.value = noParty(); note.value = ''; discountPercent.value = 0; discountAmount.value = 0
    heldOrderId.value = null; heldRef.value = null; clientRef.value = uuid(); selectedKey.value = null
  }
  function toRequest(registerId) {
    return {
      clientRef: clientRef.value, registerId, serviceMode: serviceMode.value, customerId: customer.value.id || null,
      customerName: customer.value.name || null, customerPhone: customer.value.phone || null,
      courierId: courier.value.id || null, note: note.value || null,
      discountPercent: discountPercent.value || 0, discountAmount: discountAmount.value || 0, heldOrderId: heldOrderId.value,
      lines: lines.value.map(l => ({
        productId: l.productId, quantity: l.quantity, unitPrice: l.unitPrice, discountPercent: l.discountPercent || 0, discountAmount: l.discountAmount || 0,
        note: l.note || null, modifierIds: expandModifiers(l.modifiers),
        components: (l.components || []).map(c => ({ productId: c.productId, quantity: c.quantity || 1, modifierIds: expandModifiers(c.modifiers), note: c.note || null }))
      }))
    }
  }
  /** Rebuild the cart from a held order (OrderDto). */
  function loadFromOrder(order, productsById) {
    clear()
    heldOrderId.value = order.id; heldRef.value = order.heldRef
    serviceMode.value = order.serviceMode || serviceMode.value
    customer.value = { id: order.customerId || null, name: order.customerName || '', phone: order.customerPhone || '' }
    courier.value = { id: order.courierId || null, name: order.courierName || '', phone: '' }
    note.value = order.note || ''
    discountPercent.value = Number(order.discountPercent) || 0; discountAmount.value = Number(order.discountAmount) || 0
    for (const ol of order.lines) {
      const product = productsById[ol.productId]
      if (!product) continue
      const modifiers = (ol.modifiers || []).map(m => ({ id: m.modifierId, name: m.name, priceDelta: Number(m.priceDelta), quantity: m.quantity || 1 }))
      const components = (ol.components || []).map(c => ({ productId: c.productId, product: productsById[c.productId], quantity: Number(c.quantity), priceDelta: Number(c.unitPrice), modifiers: (c.modifiers || []).map(m => ({ id: m.modifierId, name: m.name, priceDelta: Number(m.priceDelta) })) }))
      const l = { key: ++keySeq, productId: ol.productId, product, quantity: Number(ol.quantity), unitPrice: Number(ol.unitPrice), modifiers, components, note: ol.note || '', discountPercent: Number(ol.discountPercent) || 0, discountAmount: Number(ol.discountAmount) || 0 }
      lines.value.push(l)
    }
  }
  // ---- draft persistence: a browser refresh (or crash) must not lose the order being typed ----
  const DRAFT_KEY = 'poscaisse.cart.draft'
  function snapshot() {
    return { lines: lines.value.map(l => ({ ...l, product: undefined })), serviceMode: serviceMode.value, customer: customer.value, courier: courier.value, note: note.value,
      discountPercent: discountPercent.value, discountAmount: discountAmount.value, heldOrderId: heldOrderId.value, heldRef: heldRef.value, clientRef: clientRef.value }
  }
  watch(() => snapshot(), (d) => { try { if (d.lines.length) localStorage.setItem(DRAFT_KEY, JSON.stringify(d)); else localStorage.removeItem(DRAFT_KEY) } catch { /* ignore */ } }, { deep: true })
  /** Restore a draft saved before a refresh; products are re-resolved from the current catalog (unknown/inactive products are dropped). */
  function restoreDraft(productsById) {
    let d = null
    try { d = JSON.parse(localStorage.getItem(DRAFT_KEY) || 'null') } catch { return false }
    if (!d || !d.lines?.length || lines.value.length) return false
    const restored = []
    for (const l of d.lines) {
      const product = productsById[l.productId]
      if (!product || !product.active) continue
      const components = (l.components || []).map(c => ({ ...c, product: productsById[c.productId] })).filter(c => c.product)
      restored.push({ ...l, key: ++keySeq, product, components })
    }
    if (!restored.length) { try { localStorage.removeItem(DRAFT_KEY) } catch { /* ignore */ } return false }
    lines.value = restored; serviceMode.value = d.serviceMode || serviceMode.value; customer.value = d.customer || customer.value
    courier.value = d.courier || courier.value; note.value = d.note || ''
    discountPercent.value = d.discountPercent || 0; discountAmount.value = d.discountAmount || 0; heldOrderId.value = d.heldOrderId || null; heldRef.value = d.heldRef || null
    clientRef.value = d.clientRef || clientRef.value
    return true
  }
  return { lines, serviceMode, customer, courier, canPickCustomer, canPickCourier, needsCourier,
    note, discountPercent, discountAmount, heldOrderId, heldRef, clientRef, selectedKey, restoreDraft,
    subtotal, lineDiscountTotal, orderDiscount, total, itemCount, isEmpty, lineUnit, lineGross, lineDiscount, lineTotal,
    addLine, find, setQuantity, increment, remove, setLineDiscount, setLinePrice, setLineNote, setLineModifiers, setOrderDiscount, clear, toRequest, loadFromOrder }
})
