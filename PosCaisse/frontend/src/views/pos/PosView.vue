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
import ProductTile from '../../components/pos/ProductTile.vue'
import CartPanel from '../../components/pos/CartPanel.vue'
import ModifierDialog from '../../components/pos/ModifierDialog.vue'
import PaymentDialog from '../../components/pos/PaymentDialog.vue'
import ReceiptDialog from '../../components/pos/ReceiptDialog.vue'
import AmountDialog from '../../components/pos/AmountDialog.vue'
import TextDialog from '../../components/pos/TextDialog.vue'
import PartyDialog from '../../components/pos/PartyDialog.vue'
import HeldOrdersDialog from '../../components/pos/HeldOrdersDialog.vue'
import CashMovementDialog from '../../components/pos/CashMovementDialog.vue'
import TicketsView from './TicketsView.vue'
import Modal from '../../components/common/Modal.vue'
import Icon from '../../components/common/Icon.vue'

const router = useRouter(); const auth = useAuthStore(); const catalog = useCatalogStore(); const cart = useCartStore(); const ui = useUiStore()
const activeCat = ref('FAV'); const search = ref(''); const dialog = ref(null); const paying = ref(false); const lastSale = ref(null); const heldCount = ref(0)
const partyOverlay = ref(null)       // choix du client ou du livreur par-dessus l'encaissement
const template = ref(null); const clock = ref(fmtTime(new Date())); const menuOpen = ref(false); const cartOpen = ref(false)
let clockTimer = null

onMounted(async () => {
  try { await catalog.load(true) } catch (e) { ui.error(e.humanMessage) }
  // Le mode configure au back-office s'applique, a condition d'etre encore actif ;
  // sinon on prend le premier mode actif plutot que d'afficher un onglet impossible.
  const modes = catalog.serviceModes
  const voulu = catalog.setting('pos.defaultServiceMode', 'TAKEAWAY')
  cart.defaultServiceMode = modes.includes(voulu) ? voulu : (modes[0] || 'TAKEAWAY')
  cart.serviceMode = cart.defaultServiceMode
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
/* Un seul passage sur le catalogue plutôt qu'un filtre par catégorie à chaque rendu. */
const counts = computed(() => {
  const n = {}
  for (const p of catalog.products) n[p.categoryId] = (n[p.categoryId] || 0) + 1
  return n
})

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
function customer() { dialog.value = { kind: 'party', party: 'CUSTOMER' } }
function courier() { dialog.value = { kind: 'party', party: 'COURIER' } }
function setParty(c) { const p = dialog.value.party; dialog.value = null; if (p === 'COURIER') cart.courier = c; else cart.customer = c }

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
function checkout() {
  if (cart.isEmpty) return
  // Une course sans livreur serait une somme sortie de la caisse sans porteur connu.
  if (cart.needsCourier) { ui.error('Sélectionnez le livreur avant d\'encaisser ce ticket en livraison.'); return courier() }
  dialog.value = { kind: 'pay' }
}
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
    <header class="topbar">
      <button class="tb-icon" @click="menuOpen = !menuOpen" aria-label="Menu"><Icon name="menu" :size="21" /></button>
      <div class="ident">
        <b>{{ auth.session?.registerName }}</b>
        <span>{{ auth.user?.fullName }} · {{ clock }}</span>
      </div>

      <label class="search">
        <Icon name="search" :size="18" />
        <input id="pos-search" v-model="search" placeholder="Rechercher un produit, un code…  F3" />
        <button v-if="search" class="clear" @click="search = ''" aria-label="Effacer"><Icon name="close" :size="15" :stroke="2.2" /></button>
      </label>

      <nav class="tb-actions">
        <button class="tb-btn" @click="dialog = { kind: 'held' }">
          <Icon name="pause" :size="18" /><span>Attente</span>
          <em v-if="heldCount" class="count num">{{ heldCount }}</em>
        </button>
        <button class="tb-btn" @click="dialog = { kind: 'tickets' }"><Icon name="receipt" :size="18" /><span>Tickets</span></button>
        <button class="tb-btn" v-if="auth.can('CASH_MOVEMENT')" @click="dialog = { kind: 'cash' }"><Icon name="drawer" :size="18" /><span>Caisse</span></button>
        <button class="tb-btn cart-toggle" @click="cartOpen = !cartOpen"><Icon name="cart" :size="18" /><span class="num">{{ fmt(cart.total) }}</span></button>
      </nav>
    </header>

    <div class="body">
      <aside class="rail scroll">
        <button class="cat" :class="{ on: activeCat === 'FAV' && !search }" style="--c: #C8441C" @click="search = ''; activeCat = 'FAV'">
          <Icon name="star" :size="18" class="glyph" /><span>Favoris</span>
          <b class="tally num">{{ catalog.favorites.length }}</b>
        </button>
        <button v-for="c in catalog.categories" :key="c.id" class="cat" :class="{ on: activeCat === c.id && !search }"
                :style="{ '--c': c.color }" @click="search = ''; activeCat = c.id">
          <em v-if="c.icon" class="glyph emoji">{{ c.icon }}</em>
          <i v-else class="glyph chip"></i>
          <span>{{ c.name }}</span>
          <b class="tally num">{{ counts[c.id] || 0 }}</b>
        </button>
      </aside>

      <main class="board">
        <div class="grid scroll" :class="tileSize">
          <ProductTile v-for="p in products" :key="p.id" :product="p" :size="tileSize" :show-images="showImages"
                       :class="{ flash: flashed === p.id }" @tap="tap(p)" @hold="hold(p)" />
          <p v-if="!products.length && !catalog.loading" class="empty">{{ search ? 'Aucun produit ne correspond' : 'Aucun produit dans cette catégorie' }}</p>
        </div>
      </main>

      <CartPanel class="cart-col" @edit="editLine" @quantity="quantity" @discount="discount" @price="price"
                 @note="note" @checkout="checkout" @hold="holdOrder" @clear="clearCart" @customer="customer" @courier="courier" />
    </div>

    <!-- tiroir latéral -->
    <div v-if="menuOpen" class="drawer" @click.self="menuOpen = false">
      <div class="drawer-panel">
        <div class="drawer-head">
          <div>
            <b>{{ auth.user?.fullName }}</b>
            <span class="tiny muted">{{ auth.user?.roleName }}</span>
          </div>
          <button class="btn ghost icon" @click="menuOpen = false"><Icon name="close" :size="18" /></button>
        </div>
        <dl class="drawer-info">
          <div><dt>Point de vente</dt><dd>{{ auth.session?.pointOfSaleName }}</dd></div>
          <div><dt>Caisse</dt><dd>{{ auth.session?.registerName }}</dd></div>
          <div><dt>Ouverte à</dt><dd class="num">{{ fmtTime(auth.session?.openedAt) }}</dd></div>
          <div><dt>Fond initial</dt><dd class="num">{{ fmt(auth.session?.openingFloat, true) }}</dd></div>
        </dl>
        <nav class="drawer-nav">
          <button @click="menuOpen = false; dialog = { kind: 'held' }"><Icon name="pause" :size="18" />Commandes en attente<em v-if="heldCount" class="count num">{{ heldCount }}</em></button>
          <router-link to="/tickets"><Icon name="receipt" :size="18" />Historique des tickets</router-link>
          <button v-if="auth.can('CASH_MOVEMENT')" @click="menuOpen = false; dialog = { kind: 'cash' }"><Icon name="drawer" :size="18" />Entrée / sortie de caisse</button>
          <button @click="menuOpen = false; orderNote()"><Icon name="note" :size="18" />Note de commande</button>
          <router-link v-if="auth.isBackoffice" to="/admin"><Icon name="settings" :size="18" />Back-office</router-link>
          <button v-if="auth.can('REGISTER_CLOSE')" class="danger" @click="goClose"><Icon name="lock" :size="18" />Clôturer la caisse</button>
          <button @click="logout"><Icon name="logout" :size="18" />Déconnexion</button>
        </nav>
        <p class="drawer-foot tiny">F2 encaisser · F4 attente · F3 recherche · Suppr retirer la ligne</p>
      </div>
    </div>

    <ModifierDialog v-if="dialog?.kind === 'modifier'" :product="dialog.product" :initial="dialog.initial" @close="dialog = null" @confirm="onModifierConfirm" />
    <PaymentDialog v-if="dialog?.kind === 'pay'" :total="cart.total" :busy="paying" @close="dialog = null" @confirm="pay"
                   @customer="partyOverlay = 'CUSTOMER'" @courier="partyOverlay = 'COURIER'" />
    <PartyDialog v-if="partyOverlay" :party="partyOverlay" :initial="partyOverlay === 'COURIER' ? cart.courier : cart.customer"
                 @close="partyOverlay = null"
                 @ok="c => { if (partyOverlay === 'COURIER') cart.courier = c; else cart.customer = c; partyOverlay = null }" />
    <AmountDialog v-if="dialog?.kind === 'qty'" title="Quantité" mode="integer" :initial="dialog.line.quantity" ok-label="Valider" @close="dialog = null" @ok="setQty" />
    <AmountDialog v-if="dialog?.kind === 'discount'" :title="dialog.line ? 'Remise sur la ligne' : 'Remise sur la commande'" mode="amount"
                  :initial="dialog.line ? dialog.line.discountPercent : cart.discountPercent" hint="Remise exprimée en pourcentage"
                  :options="[{ label: '0 %', value: 0 }, { label: '5 %', value: 5 }, { label: '10 %', value: 10 }, { label: '20 %', value: 20 }, { label: '50 %', value: 50 }]"
                  ok-label="Appliquer" @close="dialog = null" @ok="setDiscount" />
    <AmountDialog v-if="dialog?.kind === 'price'" title="Nouveau prix unitaire" mode="amount" :initial="dialog.line.unitPrice" ok-label="Appliquer" @close="dialog = null" @ok="setPrice" />
    <TextDialog v-if="dialog?.kind === 'note'" title="Note sur la ligne" :initial="dialog.line.note" placeholder="ex. sans sel, bien cuit…" @close="dialog = null" @ok="setNote" />
    <TextDialog v-if="dialog?.kind === 'orderNote'" title="Note de commande" :initial="cart.note" placeholder="Remarque pour la préparation ou la livraison" @close="dialog = null" @ok="v => { cart.note = v; dialog = null }" />
    <PartyDialog v-if="dialog?.kind === 'party'" :party="dialog.party"
                 :initial="dialog.party === 'COURIER' ? cart.courier : cart.customer" @close="dialog = null" @ok="setParty" />
    <HeldOrdersDialog v-if="dialog?.kind === 'held'" @close="dialog = null; refreshHeld()" @resume="resume" />
    <CashMovementDialog v-if="dialog?.kind === 'cash'" @close="dialog = null" />
    <Modal v-if="dialog?.kind === 'tickets'" size="xl" title="Historique des tickets" @close="dialog = null">
      <TicketsView embedded />
    </Modal>

    <Modal v-if="dialog?.kind === 'done'" size="md" :closable="false">
      <template #head>
        <span class="done-mark"><Icon name="check" :size="20" :stroke="2.6" /></span>
        <div class="grow">
          <h2>Vente enregistrée</h2>
          <span class="tiny muted">Ticket {{ dialog.order.ticketNumber }}</span>
        </div>
      </template>
      <div class="done">
        <div class="done-left">
          <div class="done-total">
            <span class="eyebrow">Total encaissé</span>
            <b class="num">{{ fmt(dialog.order.total, true) }}</b>
            <span class="small muted">{{ dialog.order.payments.map(p => p.methodName + ' ' + fmt(p.amount)).join('  +  ') }}</span>
          </div>
          <div class="done-change" v-if="Number(dialog.order.changeAmount) > 0">
            <span class="eyebrow">Monnaie à rendre</span>
            <b class="num">{{ fmt(dialog.order.changeAmount, true) }}</b>
          </div>
        </div>
        <ReceiptInline :jobs="dialog.order.printJobs" :order="dialog.order" :template="template" />
      </div>
      <template #foot>
        <button class="btn success xl grow" @click="newOrder" autofocus>Nouvelle commande</button>
      </template>
    </Modal>
  </div>
</template>

<script>
/* Aperçu du ticket et impression, dans l'écran de fin de vente. */
import { defineComponent, h, ref as vref } from 'vue'
import { printJobs } from '../../composables/usePrinter'
import { api as vapi } from '../../api'
const ReceiptInline = defineComponent({
  props: { jobs: Array, order: Object, template: Object },
  setup(props) {
    const printed = vref(false)
    async function print() {
      await printJobs(props.jobs, props.template)
      printed.value = true
      try { await vapi.pos.ackPrint(props.jobs.map(j => j.id)) } catch { /* ignore */ }
    }
    const copies = () => (props.jobs || []).reduce((s, j) => s + j.copies, 0)
    return () => h('div', { class: 'ri' }, [
      h('div', { class: 'ri-tabs' }, (props.jobs || []).map(j => h('span', { class: 'badge', key: j.id }, `${j.title} ×${j.copies}`))),
      h('pre', {
        class: 'receipt-paper ri-paper',
        style: { width: (props.template?.paperWidth || 80) <= 58 ? '208px' : '278px', fontSize: '10.5px' }
      }, props.jobs?.[0]?.content || ''),
      h('button', { class: 'btn primary lg block', onClick: print }, printed.value ? 'Réimprimer les tickets' : `Imprimer les tickets (${copies()})`)
    ])
  }
})
export default { components: { ReceiptInline } }
</script>

<style scoped>
.pos { display: flex; flex-direction: column; height: 100vh; overflow: hidden; background: var(--canvas); }

/* ---------- barre supérieure ---------- */
.topbar {
  display: flex; align-items: center; gap: 10px; padding: 0 12px; min-height: 58px;
  background: var(--ink); color: #EDE8E1; border-bottom: 1px solid #000;
}
.tb-icon { width: 42px; height: 42px; display: flex; align-items: center; justify-content: center; border-radius: var(--r-sm); color: #EDE8E1; }
.tb-icon:hover { background: rgba(255, 255, 255, .1); }
.ident { display: flex; flex-direction: column; line-height: 1.2; padding-right: 12px; border-right: 1px solid rgba(255, 255, 255, .14); }
.ident b { font-family: var(--font-display); font-size: 15px; font-weight: 650; letter-spacing: -.01em; color: #fff; }
.ident span { font-size: 12px; color: #A69C90; }

.search { flex: 1; max-width: 540px; display: flex; align-items: center; gap: 9px; height: 42px; padding: 0 12px;
  background: rgba(255, 255, 255, .08); border: 1px solid transparent; border-radius: var(--r-sm); color: #A69C90; transition: background .12s, border-color .12s; }
.search:focus-within { background: rgba(255, 255, 255, .13); border-color: rgba(255, 255, 255, .25); }
.search input { flex: 1; min-width: 0; background: none; border: 0; outline: none; color: #fff; font-size: 14.5px; }
.search input::placeholder { color: #8A8076; }
.clear { color: #A69C90; display: flex; padding: 4px; }
.clear:hover { color: #fff; }

.tb-actions { display: flex; align-items: center; gap: 4px; margin-left: auto; }
.tb-btn {
  position: relative; display: flex; align-items: center; gap: 7px; height: 42px; padding: 0 13px;
  border-radius: var(--r-sm); color: #D8D1C8; font-size: 13.5px; font-weight: 600;
}
.tb-btn:hover { background: rgba(255, 255, 255, .1); color: #fff; }
.count {
  font-style: normal; font-size: 11px; font-weight: 800; min-width: 19px; height: 19px; padding: 0 5px;
  display: inline-flex; align-items: center; justify-content: center;
  background: var(--brand); color: #fff; border-radius: 999px;
}
.cart-toggle { display: none; background: rgba(255, 255, 255, .1); }

/* ---------- corps : rail | produits | panier ---------- */
.body {
  flex: 1; min-height: 0;
  display: grid;
  grid-template-columns: 108px minmax(0, 1fr) clamp(322px, 23.5vw, 412px);
  grid-template-rows: minmax(0, 1fr);
}

.rail { display: flex; flex-direction: column; gap: 3px; padding: 8px 6px; background: var(--surface); border-right: 1px solid var(--line); }
.cat {
  position: relative; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 5px;
  min-height: 72px; padding: 9px 6px; border-radius: var(--r-sm);
  font-size: 12.5px; font-weight: 600; line-height: 1.15; letter-spacing: -.01em; color: var(--ink-2); text-align: center;
}
.cat::before { content: ''; position: absolute; left: 3px; top: 14px; bottom: 14px; width: 3px; border-radius: 2px; background: var(--c); }
.cat:hover { background: var(--surface-2); color: var(--ink); }
.cat.on { background: var(--ink); color: #fff; }
.cat .glyph { height: 20px; display: flex; align-items: center; justify-content: center; color: var(--c); }
.cat .glyph.emoji { font-size: 18px; font-style: normal; line-height: 1; }
.cat .glyph.chip { width: 20px; border-radius: 5px; background: var(--c); opacity: .85; }
.cat span { display: block; max-width: 100%; }
.cat .tally { font-size: 11px; font-weight: 700; letter-spacing: 0; color: var(--ink-4); }
.cat.on .tally { color: rgba(255, 255, 255, .6); }

.board { display: flex; flex-direction: column; min-width: 0; min-height: 0; }
.grid {
  flex: 1; min-height: 0; padding: 12px 16px 16px;
  display: grid; align-content: start;
  /* Tuile horizontale : vignette carree a gauche, prix et libelle a droite.
     Les colonnes s'elargissent pour loger les deux, les lignes se raccourcissent
     puisque plus rien n'est empile. Au total, plus d'articles a l'ecran. */
  grid-template-columns: repeat(auto-fill, minmax(clamp(196px, 16vw, 264px), 1fr));
  grid-auto-rows: clamp(84px, 10.6vh, 110px);
  gap: 9px;
}
.grid.S { grid-template-columns: repeat(auto-fill, minmax(clamp(168px, 13.5vw, 222px), 1fr)); grid-auto-rows: clamp(72px, 9vh, 94px); gap: 7px; }
.grid.L { grid-template-columns: repeat(auto-fill, minmax(clamp(236px, 20vw, 312px), 1fr)); grid-auto-rows: clamp(104px, 13vh, 134px); gap: 11px; }
.grid .empty { grid-column: 1 / -1; }
.flash { box-shadow: 0 0 0 2px var(--pay); }

/* ---------- tiroir ---------- */
.drawer { position: fixed; inset: 0; z-index: 80; background: rgba(20, 17, 14, .45); animation: fade .12s ease-out; }
.drawer-panel { width: min(92vw, 340px); height: 100%; background: var(--surface); display: flex; flex-direction: column; box-shadow: var(--shadow-3); }
.drawer-head { display: flex; align-items: center; gap: 10px; padding: 16px 16px 14px; border-bottom: 1px solid var(--line); }
.drawer-head > div { flex: 1; display: flex; flex-direction: column; }
.drawer-head b { font-family: var(--font-display); font-size: 16px; }
.drawer-info { margin: 0; padding: 12px 16px; display: flex; flex-direction: column; gap: 7px; background: var(--surface-2); border-bottom: 1px solid var(--line); }
.drawer-info > div { display: flex; justify-content: space-between; gap: 12px; }
.drawer-info dt { font-size: 12.5px; color: var(--ink-3); }
.drawer-info dd { margin: 0; font-size: 13px; font-weight: 650; }
.drawer-nav { display: flex; flex-direction: column; padding: 8px; gap: 1px; overflow: auto; flex: 1; }
.drawer-nav a, .drawer-nav button {
  display: flex; align-items: center; gap: 11px; min-height: 46px; padding: 0 12px;
  border-radius: var(--r-sm); font-size: 14.5px; font-weight: 600; color: var(--ink-2); text-align: left;
}
.drawer-nav a:hover, .drawer-nav button:hover { background: var(--surface-3); color: var(--ink); }
.drawer-nav .danger { color: var(--danger); }
.drawer-nav .count { margin-left: auto; }
.drawer-foot { padding: 12px 16px; margin: 0; color: var(--ink-4); border-top: 1px solid var(--line); }

/* ---------- fin de vente ---------- */
.done-mark { width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; background: var(--pay-soft); color: var(--pay); border: 1px solid var(--pay-line); }
.done { display: grid; grid-template-columns: 1fr auto; gap: 24px; align-items: start; }
.done-left { display: flex; flex-direction: column; gap: 14px; }
.done-total { display: flex; flex-direction: column; gap: 3px; }
.done-total b { font-family: var(--font-display); font-size: 36px; font-weight: 750; letter-spacing: -.03em; line-height: 1.05; }
.done-change { display: flex; flex-direction: column; gap: 3px; padding: 14px 16px; border-radius: var(--r-lg); background: var(--pay-soft); border: 1px solid var(--pay-line); color: var(--pay-2); }
.done-change b { font-family: var(--font-display); font-size: 42px; font-weight: 750; letter-spacing: -.035em; line-height: 1.05; }
:deep(.ri) { display: flex; flex-direction: column; gap: 9px; align-items: stretch; width: 278px; }
:deep(.ri-tabs) { display: flex; gap: 5px; flex-wrap: wrap; }
:deep(.ri-paper) { max-height: 244px; overflow: auto; }

/* ---------- adaptations écran ---------- */
@media (min-width: 1700px) {
  .body { grid-template-columns: 124px minmax(0, 1fr) clamp(370px, 21vw, 452px); }
  .cat { min-height: 76px; font-size: 13.5px; }
}
@media (max-width: 1180px) {
  .body { grid-template-columns: 96px minmax(0, 1fr) minmax(320px, 32vw); }
  .tb-btn span { display: none; }
  .tb-btn { padding: 0 11px; }
}
@media (max-width: 900px) {
  .body { grid-template-columns: 88px minmax(0, 1fr); }
  .cart-col { display: none; }
  .cart-toggle { display: flex; }
  .cart-toggle span { display: inline; }
  .pos.cart-open .cart-col { display: flex; position: fixed; right: 0; top: 58px; bottom: 0; width: min(100%, 420px); z-index: 60; box-shadow: var(--shadow-3); }
  .ident { display: none; }
  .done { grid-template-columns: 1fr; }
  :deep(.ri) { width: 100%; }
}
</style>
