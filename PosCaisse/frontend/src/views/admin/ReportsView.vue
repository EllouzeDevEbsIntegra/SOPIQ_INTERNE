<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { fmt } from '../../utils/money'
import { fmtDateTime, isoDate } from '../../utils/dates'
import PeriodPicker from '../../components/common/PeriodPicker.vue'
const ui = useUiStore()
const types = [
  { k: 'daily', l: 'CA journalier' }, { k: 'hourly', l: 'Ventes par heure' }, { k: 'products', l: 'Ventes par produit' }, { k: 'categories', l: 'Ventes par catégorie' },
  { k: 'cashiers', l: 'Ventes par caissier' }, { k: 'registers', l: 'Ventes par caisse' }, { k: 'pos', l: 'Ventes par point de vente' }, { k: 'payments', l: 'Moyens de paiement' },
  { k: 'discounts', l: 'Remises' }, { k: 'cancellations', l: 'Annulations' }, { k: 'refunds', l: 'Remboursements' }, { k: 'movements', l: 'Mouvements de caisse' }, { k: 'closures', l: 'Clôtures de caisse' }, { k: 'differences', l: 'Écarts de caisse' }
]
const labels = { day: 'Jour', hour: 'Heure', tickets: 'Tickets', revenue: 'CA', average_ticket: 'Panier moyen', discounts: 'Remises', refunds: 'Remb.', name: 'Nom', quantity: 'Quantité', code: 'Code', kind: 'Type', payments: 'Paiements', amount: 'Montant',
  ticket_number: 'Ticket', paid_at: 'Date', cashier: 'Caissier', subtotal: 'Sous-total', line_discount_total: 'Remises lignes', discount_percent: 'Remise %', discount_amount: 'Remise', total: 'Total', cancelled_at: 'Annulé le', cancelled_by: 'Par', cancel_reason: 'Motif',
  created_at: 'Date', user_name: 'Utilisateur', method: 'Moyen', reason: 'Motif', register: 'Caisse', opened_by: 'Caissier', opened_at: 'Ouverture', closed_at: 'Clôture', opening_float: 'Fond', cash_sales: 'Espèces', card_sales: 'Carte', other_sales: 'Autres',
  cash_in: 'Entrées', cash_out: 'Sorties', expected_cash: 'Théorique', counted_cash: 'Compté', cash_difference: 'Écart', tickets_count: 'Tickets', closing_note: 'Note', type: 'Type', comment: 'Commentaire', id: '#', color: 'Couleur' }
const type = ref('daily'); const from = ref(isoDate()); const to = ref(isoDate()); const rows = ref([]); const loading = ref(false)
async function load() { loading.value = true; try { rows.value = await api.reports.report(type.value, { from: from.value, to: to.value }) } catch (e) { ui.error(e.humanMessage) } finally { loading.value = false } }
onMounted(load)
const cols = () => rows.value.length ? Object.keys(rows.value[0]).filter(c => c !== 'id' && c !== 'color') : []
const isMoney = (c) => /revenue|amount|total|discount|refund|cash|float|subtotal|expected|counted|difference|average/.test(c) && !/count|percent/.test(c)
const isDate = (c) => /_at$/.test(c)
const render = (c, v) => v === null || v === undefined ? '' : isDate(c) ? fmtDateTime(v) : isMoney(c) ? fmt(v) : String(v)
function exportCsv() { window.open(api.reports.csvUrl(type.value, { from: from.value, to: to.value }) + '&token=', '_blank') }
async function download() {
  try { const r = await fetch(api.reports.csvUrl(type.value, { from: from.value, to: to.value }), { headers: { Authorization: 'Bearer ' + localStorage.getItem('poscaisse.token') } }); const b = await r.blob(); const a = document.createElement('a'); a.href = URL.createObjectURL(b); a.download = `rapport-${type.value}-${from.value}_${to.value}.csv`; a.click() } catch (e) { ui.error('Export impossible') }
}
</script>
<template>
  <div class="toolbar"><select class="input" v-model="type" @change="load"><option v-for="t in types" :key="t.k" :value="t.k">{{ t.l }}</option></select><PeriodPicker v-model:from="from" v-model:to="to" @change="load" /><button class="btn" @click="download" :disabled="!rows.length">⬇ Export CSV</button></div>
  <div v-if="loading" class="spinner"></div>
  <div v-else class="table-wrap"><table class="table">
    <thead><tr><th v-for="c in cols()" :key="c" :class="{ right: isMoney(c) || /count|tickets|quantity|payments|hour/.test(c) }">{{ labels[c] || c }}</th></tr></thead>
    <tbody><tr v-for="(r, i) in rows" :key="i"><td v-for="c in cols()" :key="c" :class="{ right: isMoney(c) || /count|tickets|quantity|payments|hour/.test(c), num: true }">{{ render(c, r[c]) }}</td></tr><tr v-if="!rows.length"><td :colspan="cols().length || 1" class="empty">Aucune donnée sur la période</td></tr></tbody>
  </table></div>
</template>
