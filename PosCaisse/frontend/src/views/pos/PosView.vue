<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../../api'
import { useAuthStore } from '../../stores/auth'
import { useCatalogStore } from '../../stores/catalog'
import { useCartStore } from '../../stores/cart'
import { useUiStore } from '../../stores/ui'
import { fmt, round } from '../../utils/money'
import { fmtTime } from '../../utils/dates'
import { serviceModeLabel } from '../../utils/i18n'
import ProductTile from '../../components/pos/ProductTile.vue'
import CartPanel from '../../components/pos/CartPanel.vue'
import ModifierDialog from '../../components/pos/ModifierDialog.vue'
import PaymentDialog from '../../components/pos/PaymentDialog.vue'
import ReceiptDialog from '../../components/pos/ReceiptDialog.vue'
import AmountDialog from '../../components/pos/AmountDialog.vue'
import TextDialog from '../../components/pos/TextDialog.vue'
import CustomerDialog from '../../components/pos/CustomerDialog.vue'
import HeldOrdersDialog from '../../components/pos/HeldOrdersDialog.vue'
import CashMovementDialog from '../../components/pos/CashMovementDialog.vue'
import Modal from '../../components/common/Modal.vue'

const router = useRouter(); const auth = useAuthStore(); const catalog = useCatalogStore(); const cart = useCartStore(); const ui = useUiStore()
const activeCat = ref('FAV'); const search = ref(''); const dialog = ref(null); const paying = ref(false); const lastSale = ref(null); const heldCount = ref(0)
const template = ref(null); const clock = ref(fmtTime(new Date())); const menuOpen = ref(false); const cartOpen = ref(false)
let clockTimer = null

onMounted(async () => {
  try { await catalog.load(true) } catch (e) { ui.error(e.humanMessage) }
  cart.serviceMode = catalog.serviceModes.includes(cart.serviceMode) ? cart.serviceMode : (catalog.setting('pos.defaultServiceMode', 'TAKEAWAY'))
  if (!catalog.favorites.length && catalog.categories.length) activeCat.value = catalog.categories[0].id
  if (cart.restoreDraft(catalog.productsById)) ui.info('Commande en cours restaurée')
  api.admin.activeTemplate().then(t => { template.value = { ...t, logoData: catalog.company?.logoData } }).catch(() => {})
  refreshHeld()
  clockTimer = setInterval(() => { clock.value = fmtTime(new Date()) }, 15000)
  window.addEventListener('keydown', onKey)
})
onUnmounted(() => { clearInterval(clockTimer); window.removeEventListener('keydown', onKey) })
async function refreshHeld() { try { heldCount.value = (await api.pos.held(auth.session?.pointOfSaleId)).length } catch { /* ignore */ } }

const tileSize = computed(() => catalog.setting('pos.tileSize', 'M'))
const showImages = computed(() => catalog.setting('pos.showImages', 'true') === 'true')
const products = computed(() => {
  if (search.value.trim()) return catalog.search(search.value)
  if (activeCat.value === 'FAV') return catalog.favorites
  return catalog.byCategory(activeCat.value)
})
const activeCatObj = computed(() => catalog.categories.find(c => c.id === activeCat.value))

function tap(p) {
  if (!p.available) return ui.info(`${p.name} est indisponible`)
  const needsDialog = p.productType === 'MENU' || (p.modifierGroups || []).some(g => g.required)
  if (needsDialog) { dialog.value = { kind: 'modifier', product: p }; return }
  cart.addLine({ product: p })
  flash(p)
}
function hold(p) {
  // long press: options (if any) or availability toggle for managers
  if (p.modifierGroups?.length || p.productType === 'MENU') dialog.value = { kind: 'modifier', product: p }
  else if (auth.can('PRODUCTS_MANAGE') || auth.can('SELL')) toggleAvailability(p)
}
const flashed = ref(null)
function flash(p) { flashed.value = p.id; setTimeout(() => { if (flashed.value === p.id) flashed.value = null }, 250) }
function onModifierConfirm({ quantity, modifiers, components, note }) {
  const d = dialog.value; dialog.value = null
  if (d.line) { const l = cart.find(d.line.key); if (l) { l.quantity = quantity; l.modifiers = modifiers; l.components = components; l.note = note } }
  else cart.addLine({ product: d.product, quantity, modifiers, components, note })
}
async function toggleAvailability(p) {
  const target = !p.available
  if (!await ui.confirm({ title: target ? 'Rendre disponible' : 'Marquer indisponible', message: `${p.name} → ${target ? 'DISPONIBLE' : 'INDISPONIBLE'} ?`, okLabel: 'Confirmer' })) return
  try { const np = await api.pos.availability(p.id, target); catalog.updateProduct(np); ui.success(`${p.name} : ${target ? 'disponible' : 'indisponible'}`) } catch (e) { ui.error(e.humanMessage) }
}
// cart actions
function editLine(l) { dialog.value = { kind: 'modifier', product: l.product, line: l, initial: l } }
function quantity(l) { dialog.value = { kind: 'qty', line: l } }
function setQty(v) { const d = dialog.value; dialog.value = null; if (d.line) cart.setQuantity(d.line.key, Math.max(0, Math.floor(v))) }
function discount(l) { dialog.value = { kind: 'discount', line: l } }
function setDiscount(v) {
  const d = dialog.value; dialog.value = null
  const percent = Math.min(100, Math.max(0, v))
  const threshold = Number(catalog.setting('discount.highThresholdPercent', '10'))
  if (percent > threshold && !auth.can('DISCOUNT_HIGH')) return ui.error(`Une remise supérieure à ${threshold} % nécessite l'autorisation d'un manager.`)
  const maxUser = auth.user.maxDiscountPercent
  if (maxUser !== null && maxUser !== undefined && percent > Number(maxUser)) return ui.error(`Votre remise maximale autorisée est de ${maxUser} %.`)
  if (d.line) cart.setLineDiscount(d.line.key, percent, 0); else cart.setOrderDiscount(percent, 0)
}
function price(l) { dialog.value = { kind: 'price', line: l } }
function setPrice(v) { const d = dialog.value; dialog.value = null; if (v >= 0) cart.setLinePrice(d.line.key, v) }
function note(l) { dialog.value = { kind: 'note', line: l } }
function setNote(v) { const d = dialog.value; dialog.value = null; cart.setLineNote(d.line.key, v) }
function orderNote() { dialog.value = { kind: 'orderNote' } }
async function clearCart() { if (cart.isEmpty) return; if (await ui.confirm({ title: 'Vider le panier', message: 'Abandonner la commande en cours ?', okLabel: 'Vider', danger: true })) { if (cart.heldOrderId) { try { await api.pos.abandon(cart.heldOrderId) } catch { /* ignore */ } refreshHeld() } cart.clear() } }
function serviceMode() { dialog.value = { kind: 'service' } }
function customer() { dialog.value = { kind: 'customer' } }
function setCustomer(c) { dialog.value = null; cart.customer = c }

// hold / resume
const holding = ref(false)
async function holdOrder() {
  if (cart.isEmpty || holding.value) return
  holding.value = true
  try { const o = await api.pos.hold(cart.toRequest(auth.session.registerId)); ui.success(`Commande ${o.heldRef} mise en attente`); cart.clear(); refreshHeld() }
  catch (e) { ui.error(e.humanMessage) } finally { holding.value = false }
}
async function resume(o) {
  dialog.value = null
  if (!cart.isEmpty) { if (!await ui.confirm({ title: 'Reprendre la commande', message: 'Le panier actuel sera remplacé. Continuer ?', okLabel: 'Reprendre' })) return }
  cart.loadFromOrder(o, catalog.productsById)
  ui.info(`Commande ${o.heldRef} reprise`)
  refreshHeld()
}
// checkout
function checkout() { if (cart.isEmpty) return; dialog.value = { kind: 'pay' } }
async function pay(payments) {
  if (paying.value) return
  paying.value = true
  try {
    const order = await api.pos.checkout({ ...cart.toRequest(auth.session.registerId), payments })
    lastSale.value = order
    cart.clear()
    dialog.value = { kind: 'done', order }
    refreshHeld()
    if (catalog.setting('print.autoPreview', 'true') === 'true' && order.printJobs?.length) { /* preview shown in done dialog */ }
  } catch (e) {
    ui.error(e.humanMessage)
    if (e.response?.status === 409 && /session/i.test(e.humanMessage || '')) { auth.setSession(null); router.replace('/open') }
  } finally { paying.value = false }
}
function newOrder() { dialog.value = null }
function goClose() { if (!cart.isEmpty) return ui.error('Videz ou mettez en attente le panier avant la clôture.'); router.push('/close') }
function logout() { if (!cart.isEmpty) return ui.error('Videz ou mettez en attente le panier avant de vous déconnecter.'); auth.logout(); router.replace('/login') }
function onKey(e) {
  if (dialog.value?.kind === 'done' && (e.key === 'Enter' || e.key === 'Escape')) { e.preventDefault(); newOrder(); return }
  if (dialog.value || e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return
  if (e.key === 'F2') { e.preventDefault(); checkout() }
  if (e.key === 'F4') { e.preventDefault(); holdOrder() }
  if (e.key === 'F3') { e.preventDefault(); document.getElementById('pos-search')?.focus() }
  if (e.key === 'Delete' && cart.selectedKey && auth.can('LINE_DELETE')) cart.remove(cart.selectedKey)
  if (e.key === '+' && cart.selectedKey) cart.increment(cart.selectedKey, 1)
  if (e.key === '-' && cart.selectedKey) cart.increment(cart.selectedKey, -1)
}
watch(search, v => { if (v) activeCat.value = null; else if (!activeCat.value) activeCat.value = catalog.favorites.length ? 'FAV' : catalog.categories[0]?.id })
</script>
<template>
  <div class="pos" :class="{ 'cart-open': cartOpen }">
    <header class="top">
      <button class="btn ghost icon lg" @click="menuOpen=!menuOpen">☰</button>
      <div class="ident"><b>{{ auth.session?.registerName }}</b><span class="muted small">{{ auth.user.fullName }} · {{ clock }}</span></div>
      <div class="search"><input id="pos-search" class="input" v-model="search" placeholder="🔍 Rechercher un produit (nom, code)…  F3" /><button v-if="search" class="btn ghost icon" @click="search=''">✕</button></div>
      <button class="btn lg" @click="dialog={kind:'held'}">⏸ En attente <span v-if="heldCount" class="badge warning">{{ heldCount }}</span></button>
      <router-link class="btn lg" to="/tickets">🧾 Tickets</router-link>
      <button class="btn lg" v-if="auth.can('CASH_MOVEMENT')" @click="dialog={kind:'cash'}">💵 Caisse</button>
      <button class="btn lg cart-toggle" @click="cartOpen=!cartOpen">🛒 {{ fmt(cart.total) }}</button>
    </header>
    <nav v-if="menuOpen" class="side-menu" @click.self="menuOpen=false">
      <div class="menu-panel">
        <div class="row between mb-16"><b>{{ auth.user.fullName }}</b><button class="btn ghost icon" @click="menuOpen=false">✕</button></div>
        <div class="muted small mb-16">{{ auth.session?.pointOfSaleName }} · {{ auth.session?.registerName }} · ouverte à {{ fmtTime(auth.session?.openedAt) }} · fond {{ fmt(auth.session?.openingFloat, true) }}</div>
        <button class="btn lg block" @click="menuOpen=false; dialog={kind:'held'}">⏸ Commandes en attente</button>
        <router-link class="btn lg block" to="/tickets">🧾 Historique des tickets</router-link>
        <button class="btn lg block" v-if="auth.can('CASH_MOVEMENT')" @click="menuOpen=false; dialog={kind:'cash'}">💵 Entrée / sortie de caisse</button>
        <button class="btn lg block" @click="menuOpen=false; orderNote()">📝 Note de commande</button>
        <router-link class="btn lg block" v-if="auth.isBackoffice" to="/admin">⚙ Back-office</router-link>
        <button class="btn lg block danger" v-if="auth.can('REGISTER_CLOSE')" @click="goClose">🔒 Clôturer la caisse</button>
        <button class="btn lg block ghost" @click="logout">Déconnexion</button>
        <div class="tiny muted mt-16">Raccourcis : F2 encaisser · F4 attente · F3 recherche · Suppr supprimer ligne</div>
      </div>
    </nav>
    <div class="body">
      <aside class="cats scroll">
        <button class="cat fav" :class="{ on: activeCat==='FAV' && !search }" @click="search=''; activeCat='FAV'">⭐<span>Favoris</span></button>
        <button v-for="c in catalog.categories" :key="c.id" class="cat" :class="{ on: activeCat===c.id && !search }" :style="{ '--c': c.color }" @click="search=''; activeCat=c.id"><span class="ico">{{ c.icon || '•' }}</span><span>{{ c.name }}</span></button>
      </aside>
      <main class="grid-wrap scroll">
        <div class="grid-title"><b>{{ search ? 'Résultats' : (activeCat==='FAV' ? 'Favoris' : activeCatObj?.name) }}</b><span class="muted small">{{ products.length }} produit(s) · appui long = options / disponibilité</span></div>
        <div class="grid" :class="tileSize">
          <ProductTile v-for="p in products" :key="p.id" :product="p" :size="tileSize" :show-images="showImages" :class="{ flash: flashed===p.id }" @tap="tap(p)" @hold="hold(p)" />
        </div>
        <div v-if="!products.length && !catalog.loading" class="empty">{{ search ? 'Aucun produit ne correspond' : 'Aucun produit dans cette catégorie' }}</div>
      </main>
      <CartPanel class="cart-col" @edit="editLine" @quantity="quantity" @discount="discount" @price="price" @note="note" @checkout="checkout" @hold="holdOrder" @clear="clearCart" @customer="customer" @service="serviceMode" />
    </div>

    <ModifierDialog v-if="dialog?.kind==='modifier'" :product="dialog.product" :initial="dialog.initial" @close="dialog=null" @confirm="onModifierConfirm" />
    <PaymentDialog v-if="dialog?.kind==='pay'" :total="cart.total" :busy="paying" @close="dialog=null" @confirm="pay" />
    <AmountDialog v-if="dialog?.kind==='qty'" title="Quantité" mode="integer" :initial="dialog.line.quantity" ok-label="VALIDER" @close="dialog=null" @ok="setQty" />
    <AmountDialog v-if="dialog?.kind==='discount'" :title="dialog.line ? 'Remise sur la ligne (%)' : 'Remise sur la commande (%)'" mode="amount" :initial="dialog.line ? dialog.line.discountPercent : cart.discountPercent" :options="[{label:'0 %',value:0},{label:'5 %',value:5},{label:'10 %',value:10},{label:'20 %',value:20},{label:'50 %',value:50}]" ok-label="APPLIQUER" @close="dialog=null" @ok="setDiscount" />
    <AmountDialog v-if="dialog?.kind==='price'" title="Nouveau prix unitaire" mode="amount" :initial="dialog.line.unitPrice" ok-label="APPLIQUER" @close="dialog=null" @ok="setPrice" />
    <TextDialog v-if="dialog?.kind==='note'" title="Note sur la ligne" :initial="dialog.line.note" placeholder="ex. sans sel, bien cuit…" @close="dialog=null" @ok="setNote" />
    <TextDialog v-if="dialog?.kind==='orderNote'" title="Note de commande" :initial="cart.note" placeholder="Remarque pour la préparation / livraison" @close="dialog=null" @ok="v => { cart.note = v; dialog = null }" />
    <CustomerDialog v-if="dialog?.kind==='customer'" :initial="cart.customer" @close="dialog=null" @ok="setCustomer" />
    <HeldOrdersDialog v-if="dialog?.kind==='held'" @close="dialog=null; refreshHeld()" @resume="resume" />
    <CashMovementDialog v-if="dialog?.kind==='cash'" @close="dialog=null" />
    <Modal v-if="dialog?.kind==='service'" title="Mode de service" @close="dialog=null">
      <div class="col gap-8"><button v-for="m in catalog.serviceModes" :key="m" class="btn xl block" :class="{ primary: cart.serviceMode===m }" @click="cart.serviceMode=m; dialog=null">{{ serviceModeLabel(m) }}</button></div>
    </Modal>
    <Modal v-if="dialog?.kind==='done'" size="md" :closable="false">
      <template #head><h2>✅ Vente enregistrée — {{ dialog.order.ticketNumber }}</h2></template>
      <div class="done">
        <div class="done-main">
          <div class="big-total"><span class="muted">Total</span><b class="num">{{ fmt(dialog.order.total, true) }}</b></div>
          <div class="big-change" v-if="Number(dialog.order.changeAmount) > 0"><span>À RENDRE</span><b class="num">{{ fmt(dialog.order.changeAmount, true) }}</b></div>
          <div class="muted small">{{ dialog.order.payments.map(p => p.methodName + ' ' + fmt(p.amount)).join(' + ') }}</div>
        </div>
        <ReceiptInline :jobs="dialog.order.printJobs" :order="dialog.order" :template="template" />
      </div>
      <template #foot>
        <button class="btn success xl grow" @click="newOrder" autofocus>NOUVELLE COMMANDE ➜</button>
      </template>
    </Modal>
  </div>
</template>
<script>
// Inline receipt preview + print used by the "sale done" dialog (kept in-file to keep the flow in one place).
import { defineComponent, h, ref as vref } from 'vue'
import { printJobs } from '../../composables/usePrinter'
import { api as vapi } from '../../api'
const ReceiptInline = defineComponent({
  props: { jobs: Array, order: Object, template: Object },
  setup(props) {
    const printed = vref(false)
    async function print() { await printJobs(props.jobs, props.template); printed.value = true; try { await vapi.pos.ackPrint(props.jobs.map(j => j.id)) } catch { /* ignore */ } }
    return () => h('div', { class: 'ri' }, [
      h('div', { class: 'ri-jobs' }, (props.jobs || []).map(j => h('span', { class: 'badge', key: j.id }, `${j.title} ×${j.copies}`))),
      h('pre', { class: 'receipt-paper ri-paper', style: { width: (props.template?.paperWidth || 80) <= 58 ? '200px' : '272px', fontSize: '10.5px' } }, props.jobs?.[0]?.content || ''),
      h('button', { class: 'btn lg primary block', onClick: print }, printed.value ? '🖨 Réimprimer les tickets' : `🖨 Imprimer les tickets (${(props.jobs || []).reduce((s, j) => s + j.copies, 0)})`)
    ])
  }
})
export default { components: { ReceiptInline } }
</script>
<style scoped>
.pos { display: flex; flex-direction: column; height: 100vh; overflow: hidden; }
.top { display: flex; align-items: center; gap: 8px; padding: 8px 12px; background: var(--primary); color: #fff; min-height: 64px; }
.top .btn { background: rgba(255,255,255,.08); border-color: transparent; color: #fff; }
.top .btn.ghost { background: transparent; }
.ident { display: flex; flex-direction: column; line-height: 1.15; min-width: 120px; } .ident .muted { color: #94a3b8; }
.search { flex: 1; display: flex; align-items: center; gap: 4px; min-width: 160px; } .search .input { background: #1e293b; border-color: #334155; color: #fff; min-height: 46px; }
.search .input::placeholder { color: #94a3b8; }
.cart-toggle { display: none; }
.side-menu { position: fixed; inset: 0; background: rgba(15,23,42,.45); z-index: 60; }
.menu-panel { width: min(92vw, 360px); height: 100%; background: var(--surface); padding: 18px; display: flex; flex-direction: column; gap: 8px; overflow: auto; box-shadow: var(--shadow-lg); }
.body { flex: 1; display: grid; grid-template-columns: 128px 1fr minmax(340px, 30%); grid-template-rows: minmax(0, 1fr); min-height: 0; }
.cats { display: flex; flex-direction: column; gap: 6px; padding: 8px; background: var(--surface); border-right: 1px solid var(--border); }
.cat { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px; min-height: 76px; border-radius: 12px; font-weight: 700; font-size: 13px; background: var(--surface-2); border: 2px solid transparent; border-bottom: 4px solid var(--c, #94a3b8); text-align: center; line-height: 1.1; padding: 6px 4px; }
.cat .ico { font-size: 24px; } .cat.on { background: var(--c, #0f172a); color: #fff; border-color: var(--c, #0f172a); }
.cat.fav { --c: #f59e0b; } .cat.fav.on { background: #f59e0b; color: #fff; }
.grid-wrap { padding: 10px 12px; }
.grid-title { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 8px; padding: 0 2px; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 10px; }
.grid.S { grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); gap: 8px; } .grid.L { grid-template-columns: repeat(auto-fill, minmax(190px, 1fr)); gap: 12px; }
.flash { outline: 3px solid var(--success); }
.done { display: grid; grid-template-columns: 1fr 1.3fr; gap: 20px; }
.done-main { display: flex; flex-direction: column; gap: 12px; }
.big-total { display: flex; flex-direction: column; } .big-total b { font-size: 34px; }
.big-change { background: var(--success-soft); border: 2px solid #bbf7d0; border-radius: 14px; padding: 14px; display: flex; flex-direction: column; color: var(--success-2); }
.big-change span { font-weight: 700; letter-spacing: .05em; } .big-change b { font-size: 44px; line-height: 1.1; }
:deep(.ri) { display: flex; flex-direction: column; gap: 8px; align-items: center; } :deep(.ri-jobs) { display: flex; gap: 6px; flex-wrap: wrap; }
:deep(.ri-paper) { max-height: 260px; overflow: auto; max-width: 100%; }
@media (max-width: 1100px) { .body { grid-template-columns: 104px 1fr minmax(300px, 34%); } .cat { min-height: 64px; font-size: 12px; } .cat .ico { font-size: 20px; } }
@media (max-width: 860px) {
  .body { grid-template-columns: 90px 1fr; } .cart-col { display: none; } .cart-toggle { display: inline-flex; }
  .pos.cart-open .cart-col { display: flex; position: fixed; right: 0; top: 64px; bottom: 0; width: min(100%, 420px); z-index: 40; box-shadow: var(--shadow-lg); }
  .done { grid-template-columns: 1fr; }
  .top .btn:not(.cart-toggle):not(.icon) { display: none; }
}
</style>
