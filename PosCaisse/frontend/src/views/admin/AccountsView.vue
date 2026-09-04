<script setup>
/**
 * Comptes à crédit : soldes, relevé d'un compte (tickets portés et règlements) et
 * encaissement d'un règlement. Deux natures de titulaire, tenues à l'identique :
 * les clients (tickets à emporter portés au compte) et les livreurs (courses confiées,
 * dont ils détiennent l'argent jusqu'au versement).
 */
import { computed, onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import { fmt, fmtQty, parseAmount } from '../../utils/money'
import { fmtDateTime, startOfDayIso, endOfDayIso } from '../../utils/dates'
import Modal from '../../components/common/Modal.vue'
import Icon from '../../components/common/Icon.vue'
import OrderDetailDialog from '../../components/pos/OrderDetailDialog.vue'

const ui = useUiStore(); const { busy, run } = useBusy()
const PARTIES = [
  { key: 'CUSTOMER', tab: 'Clients', one: 'client', charged: 'Porté au compte', empty: 'Aucun client à afficher.', tickets: 'Tickets portés au compte' },
  { key: 'COURIER', tab: 'Livreurs', one: 'livreur', charged: 'Courses confiées', empty: 'Aucun livreur à afficher.', tickets: 'Courses confiées' }
]
const party = ref('CUSTOMER')
const meta = computed(() => PARTIES.find(p => p.key === party.value))

const rows = ref([]); const withDebtOnly = ref(true); const q = ref('')
const selected = ref(null)          // relevé du compte ouvert
const period = ref({ from: '', to: '' })
const methods = ref([])
const pay = ref(null)               // formulaire de règlement
const orderId = ref(null)           // ticket dont on regarde le détail

const filtered = computed(() => {
  const s = q.value.trim().toLowerCase()
  return rows.value.filter(c => !s || (c.name + ' ' + (c.phone || '')).toLowerCase().includes(s))
})
const totalDebt = computed(() => rows.value.reduce((s, c) => s + Number(c.balance), 0))

async function load() {
  try {
    rows.value = await api.accounts.balances(party.value, withDebtOnly.value)
    // Les moyens de paiement sont servis par le catalogue, pas par l'espace admin.
    if (!methods.value.length) methods.value = (await api.catalog.paymentMethods()).filter(m => m.kind !== 'CREDIT' && m.active)
  } catch (e) { ui.error(e.humanMessage) }
}
onMounted(load)
function switchParty(k) { party.value = k; selected.value = null; q.value = ''; load() }

const periodParams = () => ({
  from: period.value.from ? startOfDayIso(period.value.from) : undefined,
  to: period.value.to ? endOfDayIso(period.value.to) : undefined
})

async function open(c) {
  try {
    selected.value = await api.accounts.statement(party.value, c.partyId, periodParams())
  } catch (e) { ui.error(e.humanMessage) }
}
const reload = () => selected.value && open({ partyId: selected.value.partyId })

/* Le relevé est produit par le serveur et téléchargé, plutôt qu'imprimé depuis la page :
   la caisse tourne dans un navigateur lancé en impression directe, où un window.print()
   partirait droit sur l'imprimante à tickets. Un PDF s'ouvre, s'imprime où l'on veut et
   se joint à un courriel. */
const pdfBusy = ref(false)
async function printStatement() {
  pdfBusy.value = true
  try {
    const name = await api.accounts.statementPdf(party.value, selected.value.partyId, periodParams())
    ui.success('Relevé téléchargé : ' + name)
  } catch (e) { ui.error(e) } finally { pdfBusy.value = false }
}

function startPayment() { pay.value = { paymentMethodId: methods.value[0]?.id, amount: '', note: '' } }
async function savePayment() {
  const amount = parseAmount(pay.value.amount)
  if (!amount) return ui.error('Saisissez un montant.')
  const r = await run(() => api.accounts.pay(party.value, {
    partyId: selected.value.partyId, paymentMethodId: pay.value.paymentMethodId,
    amount, note: pay.value.note || null
  }), { success: 'Règlement enregistré' })
  if (r) { pay.value = null; await reload(); await load() }
}
async function removePayment(p) {
  if (!await ui.confirm({ title: 'Supprimer le règlement', message: `Supprimer ${p.number} (${fmt(p.amount)}) ? Le solde remontera d'autant.`, okLabel: 'Supprimer', danger: true })) return
  if (await run(() => api.accounts.deletePayment(party.value, p.id), { success: 'Règlement supprimé' })) { await reload(); await load() }
}
</script>

<template>
  <div class="tabs">
    <button v-for="p in PARTIES" :key="p.key" :class="{ on: party === p.key }" @click="switchParty(p.key)">{{ p.tab }}</button>
  </div>

  <!-- ---------- liste des soldes ---------- -->
  <div class="toolbar">
    <input class="input" v-model="q" :placeholder="'Rechercher un ' + meta.one + '…'" style="max-width:280px" />
    <label class="check"><input type="checkbox" v-model="withDebtOnly" @change="load" /> Uniquement ceux qui doivent</label>
    <span class="grow"></span>
    <span class="muted small">{{ filtered.length }} {{ meta.one }}(s)</span>
    <span class="total-debt">Encours total <b class="num">{{ fmt(totalDebt, true) }}</b></span>
  </div>

  <div class="table-wrap"><table class="table">
    <thead><tr><th>{{ meta.tab.slice(0, -1) }}</th><th>Téléphone</th><th class="right">{{ meta.charged }}</th><th class="right">Réglé</th><th class="right">Solde</th><th></th></tr></thead>
    <tbody>
      <tr v-for="c in filtered" :key="c.partyId">
        <td><b>{{ c.name }}</b></td>
        <td class="small">{{ c.phone }}</td>
        <td class="right num">{{ fmt(c.charged) }}</td>
        <td class="right num">{{ fmt(c.paid) }}</td>
        <td class="right num bold" :class="{ due: Number(c.balance) > 0 }">{{ fmt(c.balance) }}</td>
        <td class="actions"><button class="btn sm" @click="open(c)">Relevé</button></td>
      </tr>
      <tr v-if="!filtered.length"><td colspan="6" class="muted" style="text-align:center;padding:26px">{{ meta.empty }}</td></tr>
    </tbody>
  </table></div>

  <!-- ---------- relevé d'un compte ---------- -->
  <Modal v-if="selected" size="xl" :title="'Compte : ' + selected.name" @close="selected = null">
    <div class="statement">
      <div class="summary">
        <div class="box"><span>Total des tickets</span><b class="num">{{ fmt(selected.totalTickets, true) }}</b></div>
        <div class="box"><span>Total des règlements</span><b class="num">{{ fmt(selected.totalPayments, true) }}</b></div>
        <div class="box solde" :class="{ due: Number(selected.balance) > 0 }"><span>Solde restant</span><b class="num">{{ fmt(selected.balance, true) }}</b></div>
      </div>

      <div class="row gap-8 period">
        <span class="muted small">Période</span>
        <input class="input" type="date" v-model="period.from" @change="reload" />
        <span class="muted">→</span>
        <input class="input" type="date" v-model="period.to" @change="reload" />
        <button class="btn sm" v-if="period.from || period.to" @click="period = { from: '', to: '' }; reload()">Tout</button>
        <span class="grow"></span>
        <button class="btn" :disabled="pdfBusy" @click="printStatement">
          <Icon name="printer" :size="16" />{{ pdfBusy ? 'Préparation…' : 'Imprimer / PDF' }}
        </button>
        <button class="btn primary" @click="startPayment">+ Encaisser un règlement</button>
      </div>

      <div class="cols">
        <section>
          <h3 class="card-title">{{ meta.tickets }}</h3>
          <p class="tiny muted">Cliquez une ligne pour voir le détail des articles.</p>
          <div class="table-wrap"><table class="table">
            <thead><tr><th>Date</th><th>N° ticket</th><th>Commentaire</th><th class="right">Qté</th><th class="right">Total TTC</th></tr></thead>
            <tbody>
              <tr v-for="t in selected.tickets" :key="t.orderId" class="clickable" @click="orderId = t.orderId">
                <td class="small">{{ fmtDateTime(t.date) }}</td>
                <td><b>{{ t.ticketNumber }}</b></td>
                <td class="small">{{ t.note }}</td>
                <td class="right num">{{ fmtQty(t.quantity) }}</td>
                <td class="right num bold">{{ fmt(t.total) }}</td>
              </tr>
              <tr v-if="!selected.tickets.length"><td colspan="5" class="muted" style="text-align:center;padding:18px">Aucun ticket sur la période.</td></tr>
            </tbody>
          </table></div>
        </section>

        <section>
          <h3 class="card-title">Règlements</h3>
          <p class="tiny muted">Chaque règlement diminue le solde du compte.</p>
          <div class="table-wrap"><table class="table">
            <thead><tr><th>Date</th><th>N° règl.</th><th>Moyen</th><th class="right">Montant</th><th></th></tr></thead>
            <tbody>
              <tr v-for="p in selected.payments" :key="p.id">
                <td class="small">{{ fmtDateTime(p.date) }}</td>
                <td><b>{{ p.number }}</b><div class="tiny muted" v-if="p.note">{{ p.note }}</div></td>
                <td class="small">{{ p.method }}<div class="tiny muted">{{ p.userName }}</div></td>
                <td class="right num bold">{{ fmt(p.amount) }}</td>
                <td class="actions"><button class="btn sm danger" @click="removePayment(p)">✕</button></td>
              </tr>
              <tr v-if="!selected.payments.length"><td colspan="5" class="muted" style="text-align:center;padding:18px">Aucun règlement sur la période.</td></tr>
            </tbody>
          </table></div>
        </section>
      </div>
    </div>
  </Modal>

  <!-- ---------- saisie d'un règlement ---------- -->
  <Modal v-if="pay" size="md" title="Encaisser un règlement" @close="pay = null">
    <div class="col gap-16">
      <p class="muted">Solde dû par <b>{{ selected.name }}</b> : <b class="num">{{ fmt(selected.balance, true) }}</b></p>
      <div class="field"><label>Moyen de paiement</label>
        <select class="input" v-model="pay.paymentMethodId">
          <option v-for="m in methods" :key="m.id" :value="m.id">{{ m.name }}</option>
        </select>
      </div>
      <div class="field"><label>Montant</label><input class="input lg" v-model="pay.amount" inputmode="decimal" :placeholder="fmt(selected.balance)" /></div>
      <div class="field"><label>Commentaire</label><input class="input" v-model="pay.note" placeholder="ex. chèque n° 123, acompte…" /></div>
    </div>
    <template #foot>
      <button class="btn lg" @click="pay = null">Annuler</button>
      <button class="btn lg primary" :disabled="busy" @click="savePayment">Enregistrer</button>
    </template>
  </Modal>

  <OrderDetailDialog v-if="orderId" :order-id="orderId" @close="orderId = null" />
</template>

<style scoped>
.total-debt { display: flex; align-items: baseline; gap: 8px; font-size: 12.5px; font-weight: 700; letter-spacing: .06em; text-transform: uppercase; color: var(--ink-3); }
.total-debt b { font-size: 19px; letter-spacing: -.02em; color: var(--ink); }
.due { color: var(--brand); }

.summary { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; margin-bottom: 14px; }
.summary .box { background: var(--surface-2); border: 1px solid var(--line); border-radius: var(--r); padding: 11px 14px; }
.summary .box span { display: block; font-size: 11.5px; font-weight: 700; letter-spacing: .07em; text-transform: uppercase; color: var(--ink-3); }
.summary .box b { font-size: 24px; font-weight: 750; letter-spacing: -.025em; }
.summary .solde { background: var(--brand-soft); border-color: var(--brand-line); }

.period { margin-bottom: 14px; align-items: center; }
.cols { display: grid; grid-template-columns: minmax(0, 1.35fr) minmax(0, 1fr); gap: 20px; align-items: start; }
.cols .card-title { margin-bottom: 2px; }
.cols .tiny { margin-bottom: 8px; }
tr.clickable { cursor: pointer; }
tr.clickable:hover { background: var(--surface-2); }
@media (max-width: 1100px) { .cols { grid-template-columns: 1fr; } }
</style>
