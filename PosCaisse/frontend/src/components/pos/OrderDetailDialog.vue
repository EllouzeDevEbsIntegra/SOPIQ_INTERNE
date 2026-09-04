<script setup>
/** Ticket detail with reprint / cancel / refund (permission-gated; the backend re-checks). */
import { computed, ref } from 'vue'
import Modal from '../common/Modal.vue'
import Icon from '../common/Icon.vue'
import ReceiptDialog from './ReceiptDialog.vue'
import TextDialog from './TextDialog.vue'
import AmountDialog from './AmountDialog.vue'
import { api } from '../../api'
import { useAuthStore } from '../../stores/auth'
import { useCatalogStore } from '../../stores/catalog'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import { fmt, fmtQty, sub } from '../../utils/money'
import { fmtDateTime } from '../../utils/dates'
import { serviceModeLabel, statusLabel } from '../../utils/i18n'
const props = defineProps({ orderId: Number, template: Object })
const emit = defineEmits(['close', 'changed'])
const auth = useAuthStore(); const catalog = useCatalogStore(); const ui = useUiStore()
const { busy, run } = useBusy()
const order = ref(null); const jobs = ref(null); const dialog = ref(null); const refundMethod = ref(null)
async function load() { order.value = await api.orders.get(props.orderId) }
load().catch(e => ui.error(e.humanMessage))
const remaining = computed(() => order.value ? sub(order.value.total, order.value.refundedTotal || 0) : 0)
const canCancel = computed(() => order.value && ['PAID', 'PARTIALLY_REFUNDED'].includes(order.value.status) && auth.can('TICKET_CANCEL'))
const canRefund = computed(() => order.value && ['PAID', 'PARTIALLY_REFUNDED'].includes(order.value.status) && auth.can('REFUND') && remaining.value > 0)
async function reprint() { const j = await run(() => api.orders.reprint(order.value.id)); if (j) jobs.value = j }
async function cancel(reason) {
  dialog.value = null
  if (!await ui.confirm({ title: 'Annuler le ticket', message: `Annuler définitivement le ticket ${order.value.ticketNumber} ?\nUn remboursement de ${fmt(remaining.value, true)} sera enregistré.`, okLabel: 'Annuler le ticket', danger: true })) return
  const o = await run(() => api.orders.cancel(order.value.id, reason, null), { success: 'Ticket annulé' })
  if (o) { order.value = o; emit('changed') }
}
async function refund(amount) {
  dialog.value = null
  if (!amount || amount <= 0) return
  const method = refundMethod.value || catalog.cashMethod || catalog.paymentMethods[0]
  const reason = await new Promise(resolve => { dialog.value = { kind: 'refund-reason', resolve } })
  dialog.value = null
  if (!reason) return
  const o = await run(() => api.orders.refund(order.value.id, { amount, reason, paymentMethodId: method.id }), { success: 'Remboursement enregistré' })
  if (o) { order.value = o; emit('changed') }
}
const statusClass = (s) => ({ PAID: 'success', CANCELLED: 'danger', REFUNDED: 'danger', PARTIALLY_REFUNDED: 'warning', HELD: 'info' }[s] || '')
</script>
<template>
  <Modal size="md" @close="emit('close')">
    <template #head>
      <div class="grow" v-if="order"><h2>Ticket {{ order.ticketNumber }}</h2><div class="muted small">{{ fmtDateTime(order.paidAt || order.createdAt) }} · {{ order.registerCode }} · {{ order.cashierName }} · {{ serviceModeLabel(order.serviceMode) }}</div></div>
      <span v-if="order" class="badge" :class="statusClass(order.status)">{{ statusLabel(order.status) }}</span>
    </template>
    <div v-if="!order" class="spinner"></div>
    <div v-else class="col gap-16">
      <div v-if="order.customerName" class="badge accent"><Icon name="user" :size="14" />{{ order.customerName }} {{ order.customerPhone }}</div>
      <table class="table">
        <thead><tr><th>Qté</th><th>Article</th><th class="right">P.U.</th><th class="right">Total</th></tr></thead>
        <tbody>
          <template v-for="l in order.lines" :key="l.id">
            <tr><td class="num">{{ fmtQty(l.quantity) }}</td><td><b>{{ l.productName }}</b>
              <div v-for="c in l.components" :key="c.id" class="small muted">• {{ fmtQty(c.quantity) }} {{ c.productName }}<span v-if="c.modifiers.length"> ({{ c.modifiers.map(m => ((m.quantity || 1) > 1 ? m.quantity + ' × ' : '') + m.name).join(', ') }})</span></div>
              <div v-for="m in l.modifiers" :key="m.modifierId" class="small muted">+ <template v-if="(m.quantity || 1) > 1">{{ m.quantity }} × </template>{{ m.name }}<span v-if="Number(m.priceDelta)"> ({{ fmt(Number(m.priceDelta) * (m.quantity || 1)) }})</span></div>
              <div v-if="Number(l.discountAmount)" class="small" style="color:#b45309">Remise −{{ fmt(l.discountAmount) }}</div>
              <div v-if="l.note" class="small muted">» {{ l.note }}</div></td>
              <td class="right num">{{ fmt(Number(l.unitPrice) + Number(l.modifiersTotal)) }}</td><td class="right num bold">{{ fmt(l.lineTotal) }}</td></tr>
          </template>
        </tbody>
      </table>
      <div class="sums">
        <div class="row between" v-if="Number(order.discountAmount) || Number(order.lineDiscountTotal)"><span>Sous-total</span><span class="num">{{ fmt(order.subtotal) }}</span></div>
        <div class="row between" v-if="Number(order.lineDiscountTotal)"><span>Remises lignes</span><span class="num">−{{ fmt(order.lineDiscountTotal) }}</span></div>
        <div class="row between" v-if="Number(order.discountAmount)"><span>Remise {{ order.discountPercent }} %</span><span class="num">−{{ fmt(order.discountAmount) }}</span></div>
        <div class="row between total"><span>TOTAL</span><span class="num">{{ fmt(order.total, true) }}</span></div>
        <div class="row between" v-for="p in order.payments" :key="p.id"><span>{{ p.methodName }}<span v-if="Number(p.changeGiven)" class="muted small"> (reçu {{ fmt(p.tendered) }}, rendu {{ fmt(p.changeGiven) }})</span></span><span class="num">{{ fmt(p.amount) }}</span></div>
        <div class="row between" v-for="r in order.refunds" :key="'r'+r.id" style="color:var(--danger)"><span>{{ r.kind==='CANCELLATION' ? 'Annulation' : 'Remboursement' }} {{ r.methodName }} · {{ r.reason }} · {{ r.userName }}</span><span class="num">−{{ fmt(r.amount) }}</span></div>
        <div v-if="order.cancelReason" class="badge danger">Annulé : {{ order.cancelReason }}</div>
      </div>
    </div>
    <template #foot v-if="order">
      <button class="btn lg" v-if="auth.can('TICKETS_REPRINT') && order.status!=='HELD'" :disabled="busy" @click="reprint"><Icon name="printer" :size="17" />Réimprimer (duplicata)</button>
      <button class="btn lg" v-if="canRefund" :disabled="busy" @click="dialog={kind:'refund'}">Rembourser</button>
      <button class="btn lg danger" v-if="canCancel" :disabled="busy" @click="dialog={kind:'cancel'}">Annuler le ticket</button>
      <button class="btn lg primary" @click="emit('close')">Fermer</button>
    </template>
  </Modal>
  <ReceiptDialog v-if="jobs" :jobs="jobs" :order="order" :template="template" title="Réimpression — duplicata" @close="jobs=null" />
  <TextDialog v-if="dialog?.kind==='cancel'" title="Motif d'annulation" label="Motif (obligatoire)" required :suggestions="['Erreur de saisie', 'Client parti', 'Produit indisponible', 'Réclamation client']" @close="dialog=null" @ok="cancel" />
  <AmountDialog v-if="dialog?.kind==='refund'" title="Montant à rembourser" :hint="`Restant remboursable : ${fmt(remaining, true)}`" :initial="remaining" :options="catalog.paymentMethods.map(m => ({ label: 'Via ' + m.name, value: m.id })).length ? [] : []" ok-label="Continuer" @close="dialog=null" @ok="refund" />
  <TextDialog v-if="dialog?.kind==='refund-reason'" title="Motif du remboursement" label="Motif (obligatoire)" required :suggestions="['Erreur article', 'Produit défectueux', 'Réclamation client', 'Geste commercial']" @close="dialog.resolve(null)" @ok="v => dialog.resolve(v)" />
</template>
<style scoped>
.sums { padding: 10px 12px; background: var(--surface-2); border-radius: 12px; display: flex; flex-direction: column; gap: 4px; }
.total { font-size: 22px; font-weight: 900; }
</style>
