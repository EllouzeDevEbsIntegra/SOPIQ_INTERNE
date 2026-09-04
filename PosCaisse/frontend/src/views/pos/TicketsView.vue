<script setup>
/** Ticket history — used standalone from the POS (/tickets) and embedded in the back-office. */
import { onMounted, ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { api } from '../../api'
import { useAuthStore } from '../../stores/auth'
import { useCatalogStore } from '../../stores/catalog'
import { useUiStore } from '../../stores/ui'
import { fmt } from '../../utils/money'
import { fmtDateTime, isoDate, startOfDayIso, endOfDayIso } from '../../utils/dates'
import { statusLabel, serviceModeLabel } from '../../utils/i18n'
import OrderDetailDialog from '../../components/pos/OrderDetailDialog.vue'
const route = useRoute(); const auth = useAuthStore(); const catalog = useCatalogStore(); const ui = useUiStore()
const embedded = computed(() => !!route.meta.embedded)
const f = ref({ from: isoDate(), to: isoDate(), ticket: '', status: '', registerId: '', cashierId: '', method: '', minAmount: '', maxAmount: '' })
const page = ref(0); const size = 50; const data = ref({ content: [], total: 0 }); const loading = ref(false); const selected = ref(null)
const registers = ref([]); const users = ref([]); const template = ref(null)
async function load() {
  loading.value = true
  try {
    data.value = await api.orders.search({ from: f.value.from ? startOfDayIso(f.value.from) : undefined, to: f.value.to ? endOfDayIso(f.value.to) : undefined, ticket: f.value.ticket || undefined, status: f.value.status || undefined,
      registerId: f.value.registerId || undefined, cashierId: f.value.cashierId || undefined, method: f.value.method || undefined, minAmount: f.value.minAmount || undefined, maxAmount: f.value.maxAmount || undefined, page: page.value, size })
  } catch (e) { ui.error(e.humanMessage) } finally { loading.value = false }
}
onMounted(async () => {
  catalog.load().catch(() => {})
  api.admin.activeTemplate().then(t => { template.value = { ...t, logoData: catalog.company?.logoData } }).catch(() => {})
  api.admin.registers().then(r => { registers.value = r }).catch(() => {})
  if (auth.can('USERS_MANAGE')) api.admin.users().then(u => { users.value = u }).catch(() => {})
  load()
})
function search() { page.value = 0; load() }
const pages = computed(() => Math.ceil(data.value.total / size))
const statusClass = (s) => ({ PAID: 'success', CANCELLED: 'danger', REFUNDED: 'danger', PARTIALLY_REFUNDED: 'warning' }[s] || '')
</script>
<template>
  <div class="tickets" :class="{ embedded }">
    <header v-if="!embedded" class="top"><router-link class="btn" :to="auth.session ? '/pos' : (auth.isBackoffice ? '/admin' : '/open')">← Retour</router-link><h1>Historique des tickets</h1></header>
    <div class="content">
      <div class="toolbar card tight">
        <input class="input" v-model="f.ticket" placeholder="N° ticket" @keyup.enter="search" style="width:150px" />
        <input class="input" type="date" v-model="f.from" /><span class="muted">→</span><input class="input" type="date" v-model="f.to" />
        <select class="input" v-model="f.status"><option value="">Tous statuts</option><option v-for="s in ['PAID','CANCELLED','REFUNDED','PARTIALLY_REFUNDED']" :key="s" :value="s">{{ statusLabel(s) }}</option></select>
        <select class="input" v-model="f.registerId"><option value="">Toutes caisses</option><option v-for="r in registers" :key="r.id" :value="r.id">{{ r.name }}</option></select>
        <select class="input" v-model="f.cashierId" v-if="users.length"><option value="">Tous caissiers</option><option v-for="u in users" :key="u.id" :value="u.id">{{ u.fullName }}</option></select>
        <select class="input" v-model="f.method"><option value="">Tous paiements</option><option v-for="m in catalog.paymentMethods" :key="m.code" :value="m.code">{{ m.name }}</option></select>
        <input class="input" v-model="f.minAmount" placeholder="Min" inputmode="decimal" style="width:90px" /><input class="input" v-model="f.maxAmount" placeholder="Max" inputmode="decimal" style="width:90px" />
        <button class="btn primary" @click="search">Rechercher</button>
      </div>
      <div class="table-wrap">
        <table class="table">
          <thead><tr><th>Ticket</th><th>Date</th><th>Caisse</th><th>Caissier</th><th>Mode</th><th>Client</th><th>Paiement</th><th class="right">Total</th><th>Statut</th></tr></thead>
          <tbody>
            <tr v-for="o in data.content" :key="o.id" class="clickable" @click="selected=o.id">
              <td><b>{{ o.ticketNumber }}</b><span v-if="o.heldRef" class="tiny muted"> ({{ o.heldRef }})</span></td><td>{{ fmtDateTime(o.paidAt || o.createdAt) }}</td><td>{{ o.registerCode }}</td><td>{{ o.cashierName }}</td>
              <td>{{ serviceModeLabel(o.serviceMode) }}</td><td>{{ o.customerName || '' }}</td><td>{{ o.paymentSummary }}</td>
              <td class="right num bold">{{ fmt(o.total) }}<div v-if="Number(o.refundedTotal)" class="tiny" style="color:var(--danger)">−{{ fmt(o.refundedTotal) }}</div></td>
              <td><span class="badge" :class="statusClass(o.status)">{{ statusLabel(o.status) }}</span></td>
            </tr>
            <tr v-if="!data.content.length && !loading"><td colspan="9" class="empty">Aucun ticket</td></tr>
          </tbody>
        </table>
      </div>
      <div class="row between mt-8"><span class="muted small">{{ data.total }} ticket(s)</span><div class="row gap-4" v-if="pages > 1"><button class="btn sm" :disabled="page===0" @click="page--; load()">‹</button><span class="small">{{ page+1 }} / {{ pages }}</span><button class="btn sm" :disabled="page>=pages-1" @click="page++; load()">›</button></div></div>
    </div>
    <OrderDetailDialog v-if="selected" :order-id="selected" :template="template" @close="selected=null" @changed="load" />
  </div>
</template>
<style scoped>
.tickets { height: 100vh; display: flex; flex-direction: column; overflow: hidden; } .tickets.embedded { height: auto; }
.top { display: flex; align-items: center; gap: 14px; padding: 10px 16px; background: var(--surface); border-bottom: 1px solid var(--border); } h1 { font-size: 22px; }
.content { padding: 16px; overflow: auto; flex: 1; } .embedded .content { padding: 0; }
.table-wrap { max-height: calc(100vh - 220px); }
</style>
