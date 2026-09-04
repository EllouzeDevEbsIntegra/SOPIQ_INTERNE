<script setup>
/** Options / suppléments picker, and menu composition (components) for MENU products. */
import { computed, reactive, ref } from 'vue'
import Modal from '../common/Modal.vue'
import { fmt, add, mul } from '../../utils/money'
import { useCatalogStore } from '../../stores/catalog'
import { useUiStore } from '../../stores/ui'

const props = defineProps({ product: Object, initial: Object })
const emit = defineEmits(['close', 'confirm'])
const catalog = useCatalogStore(); const ui = useUiStore()
const isMenu = computed(() => props.product.productType === 'MENU')
const quantity = ref(props.initial?.quantity || 1)
const note = ref(props.initial?.note || '')
// modifiers: groupId -> Set of modifier ids
const sel = reactive({})
for (const g of props.product.modifierGroups || []) sel[g.id] = new Set((props.initial?.modifiers || []).filter(m => g.modifiers.some(x => x.id === m.id)).map(m => m.id))
// menu components: componentId -> [{productId, quantity, modifiers}]
const comps = reactive({})
for (const c of props.product.menuComponents || []) comps[c.id] = []
if (props.initial?.components) for (const c of props.product.menuComponents || []) comps[c.id] = props.initial.components.filter(x => c.options.some(o => o.productId === x.productId)).map(x => ({ ...x }))
const activeComponent = ref(null) // {compId, option, product} when choosing sub-options
const subSel = reactive({})

function toggle(g, m) {
  const s = sel[g.id]
  if (s.has(m.id)) { s.delete(m.id); return }
  const max = g.multiple ? (g.maxSelect || 99) : 1
  if (!g.multiple) s.clear()
  if (s.size >= max) { ui.info(`Maximum ${max} option(s) pour « ${g.name} »`); return }
  s.add(m.id)
}
function chooseOption(comp, opt) {
  const product = catalog.productsById[opt.productId]
  if (!product || !opt.available) return
  const current = comps[comp.id]
  const count = current.reduce((s, x) => s + x.quantity, 0)
  if (comp.quantity === 1) comps[comp.id] = []
  else if (count >= comp.quantity) { comps[comp.id] = current.slice(1) }
  const entry = { productId: opt.productId, product, quantity: 1, priceDelta: Number(opt.priceDelta), modifiers: [] }
  comps[comp.id].push(entry)
  if ((product.modifierGroups || []).some(g => g.required)) openSub(comp, entry)
}
function openSub(comp, entry) {
  activeComponent.value = { comp, entry }
  for (const k of Object.keys(subSel)) delete subSel[k]
  for (const g of entry.product.modifierGroups) subSel[g.id] = new Set(entry.modifiers.map(m => m.id))
}
function subToggle(g, m) {
  const s = subSel[g.id]
  if (s.has(m.id)) { s.delete(m.id); return }
  if (!g.multiple) s.clear()
  const max = g.multiple ? (g.maxSelect || 99) : 1
  if (s.size >= max) return
  s.add(m.id)
}
function subOk() {
  const e = activeComponent.value.entry
  e.modifiers = []
  for (const g of e.product.modifierGroups) for (const m of g.modifiers) if (subSel[g.id].has(m.id)) e.modifiers.push({ id: m.id, name: m.name, priceDelta: Number(m.priceDelta) })
  activeComponent.value = null
}
const modifiers = computed(() => { const out = []; for (const g of props.product.modifierGroups || []) for (const m of g.modifiers) if (sel[g.id].has(m.id)) out.push({ id: m.id, name: m.name, priceDelta: Number(m.priceDelta) }); return out })
const components = computed(() => Object.values(comps).flat())
const unit = computed(() => {
  let u = Number(props.product.price)
  for (const m of modifiers.value) u = add(u, m.priceDelta)
  for (const c of components.value) u = add(u, mul(add(c.priceDelta, c.modifiers.reduce((s, m) => add(s, m.priceDelta), 0)), c.quantity))
  return u
})
const problems = computed(() => {
  const p = []
  for (const g of props.product.modifierGroups || []) { const n = sel[g.id].size; if (g.required && n < Math.max(1, g.minSelect)) p.push(`Choisissez « ${g.name} »`); else if (n > 0 && n < g.minSelect) p.push(`« ${g.name} » : minimum ${g.minSelect}`) }
  for (const c of props.product.menuComponents || []) { const n = comps[c.id].reduce((s, x) => s + x.quantity, 0); if (n !== c.quantity) p.push(`Choisissez ${c.quantity} « ${c.name} »`) }
  return p
})
function confirm() { if (problems.value.length) return ui.error(problems.value[0]); emit('confirm', { quantity: quantity.value, modifiers: modifiers.value, components: components.value, note: note.value }) }
</script>
<template>
  <Modal size="md" @close="emit('close')">
    <template #head>
      <div class="grow"><h2>{{ product.name }}</h2><div class="muted small">{{ isMenu ? 'Composez le menu' : 'Options & suppléments' }} — {{ fmt(product.price, true) }}</div></div>
      <div class="qty row gap-4"><button class="btn lg icon" @click="quantity=Math.max(1,quantity-1)">−</button><span class="qv num">{{ quantity }}</span><button class="btn lg icon" @click="quantity++">+</button></div>
    </template>
    <div v-if="activeComponent" class="sub">
      <div class="row between mb-8"><h3>{{ activeComponent.entry.product.name }} — options</h3><button class="btn sm" @click="subOk">Terminer</button></div>
      <div v-for="g in activeComponent.entry.product.modifierGroups" :key="g.id" class="group">
        <div class="gname">{{ g.name }} <span class="badge" v-if="g.required">obligatoire</span></div>
        <div class="opts"><button v-for="m in g.modifiers" :key="m.id" class="opt" :class="{ on: subSel[g.id].has(m.id) }" @click="subToggle(g, m)"><span>{{ m.name }}</span><span v-if="Number(m.priceDelta)" class="delta">+{{ fmt(m.priceDelta) }}</span></button></div>
      </div>
    </div>
    <template v-else>
      <div v-for="c in product.menuComponents" :key="c.id" class="group">
        <div class="gname">{{ c.name }} <span class="badge accent">{{ c.quantity }} au choix</span></div>
        <div class="opts">
          <button v-for="o in c.options" :key="o.productId" class="opt" :class="{ on: comps[c.id].some(x => x.productId===o.productId), off: !o.available }" @click="chooseOption(c, o)">
            <span>{{ o.productName }}</span><span v-if="Number(o.priceDelta)" class="delta">+{{ fmt(o.priceDelta) }}</span>
            <span v-if="comps[c.id].find(x => x.productId===o.productId)?.modifiers.length" class="tiny">({{ comps[c.id].find(x => x.productId===o.productId).modifiers.map(m=>m.name).join(', ') }})</span>
          </button>
        </div>
        <div v-for="e in comps[c.id].filter(x => x.product.modifierGroups?.length)" :key="e.productId" class="row mt-8"><button class="btn sm soft" @click="openSub(c, e)">Options {{ e.product.name }} ›</button></div>
      </div>
      <div v-for="g in product.modifierGroups" :key="g.id" class="group">
        <div class="gname">{{ g.name }} <span class="badge" :class="g.required ? 'accent' : ''">{{ g.required ? 'obligatoire' : 'facultatif' }}{{ g.multiple && g.maxSelect ? ` · max ${g.maxSelect}` : '' }}</span></div>
        <div class="opts"><button v-for="m in g.modifiers" :key="m.id" class="opt" :class="{ on: sel[g.id].has(m.id) }" @click="toggle(g, m)"><span>{{ m.name }}</span><span v-if="Number(m.priceDelta)" class="delta">+{{ fmt(m.priceDelta) }}</span></button></div>
      </div>
      <div class="field mt-8"><label>Remarque cuisine</label><input class="input" v-model="note" placeholder="ex. bien cuit, sans sel…" /></div>
    </template>
    <template #foot>
      <div class="grow"><span class="muted">Prix unitaire</span> <b class="num" style="font-size:20px">{{ fmt(unit, true) }}</b></div>
      <button class="btn lg" @click="emit('close')">Annuler</button>
      <button class="btn success xl" :disabled="!!activeComponent" @click="confirm">AJOUTER {{ quantity > 1 ? quantity + ' × ' : '' }}{{ fmt(mul(unit, quantity), true) }}</button>
    </template>
  </Modal>
</template>
<style scoped>
.qv { min-width: 44px; text-align: center; font-size: 24px; font-weight: 800; }
.group { margin-bottom: 16px; } .gname { font-weight: 700; margin-bottom: 8px; display: flex; align-items: center; gap: 8px; }
.opts { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 8px; }
.opt { display: flex; flex-direction: column; align-items: flex-start; gap: 2px; min-height: 58px; padding: 8px 12px; border-radius: 12px; border: 2px solid var(--border); background: var(--surface-2); font-weight: 600; text-align: left; }
.opt.on { border-color: var(--success); background: var(--success-soft); } .opt.off { opacity: .4; }
.delta { font-size: 13px; color: var(--accent-2); font-weight: 700; }
.sub { border: 2px dashed var(--border); border-radius: 12px; padding: 12px; }
</style>
