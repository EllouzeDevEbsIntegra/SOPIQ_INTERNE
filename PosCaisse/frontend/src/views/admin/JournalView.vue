<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { fmt } from '../../utils/money'
import { fmtDateTime, isoDate, startOfDayIso, endOfDayIso } from '../../utils/dates'
import { eventLabel } from '../../utils/i18n'
import PeriodPicker from '../../components/common/PeriodPicker.vue'
const ui = useUiStore()
const from = ref(isoDate()); const to = ref(isoDate()); const registerId = ref(''); const userId = ref(''); const event = ref(''); const rows = ref([]); const registers = ref([]); const users = ref([])
const events = ['SESSION_OPEN', 'SALE', 'PAYMENT', 'CANCELLATION', 'REFUND', 'CASH_IN', 'CASH_OUT', 'SESSION_CLOSE', 'DAILY_CLOSE']
async function load() { try { rows.value = await api.registers.journal({ from: startOfDayIso(from.value), to: endOfDayIso(to.value), registerId: registerId.value || undefined, userId: userId.value || undefined, event: event.value || undefined, limit: 1000 }) } catch (e) { ui.error(e.humanMessage) } }
onMounted(() => { load(); api.admin.registers().then(r => { registers.value = r }).catch(() => {}); api.admin.users().then(u => { users.value = u }).catch(() => {}) })
const cls = (e) => ({ SALE: 'success', PAYMENT: 'success', CANCELLATION: 'danger', REFUND: 'danger', CASH_OUT: 'warning', CASH_IN: 'info', SESSION_OPEN: 'info', SESSION_CLOSE: 'accent', DAILY_CLOSE: 'accent' }[e] || '')
</script>
<template>
  <div class="toolbar"><PeriodPicker v-model:from="from" v-model:to="to" @change="load" />
    <select class="input" v-model="registerId" @change="load"><option value="">Toutes caisses</option><option v-for="r in registers" :key="r.id" :value="r.id">{{ r.name }}</option></select>
    <select class="input" v-model="userId" @change="load" v-if="users.length"><option value="">Tous utilisateurs</option><option v-for="u in users" :key="u.id" :value="u.id">{{ u.fullName }}</option></select>
    <select class="input" v-model="event" @change="load"><option value="">Toutes opérations</option><option v-for="e in events" :key="e" :value="e">{{ eventLabel(e) }}</option></select>
  </div>
  <div class="table-wrap"><table class="table">
    <thead><tr><th>Date / heure</th><th>Point de vente</th><th>Caisse</th><th>Session</th><th>Utilisateur</th><th>Opération</th><th>Référence</th><th>Description</th><th class="right">Montant</th></tr></thead>
    <tbody>
      <tr v-for="j in rows" :key="j.id"><td>{{ fmtDateTime(j.createdAt) }}</td><td>{{ j.pointOfSaleName }}</td><td>{{ j.registerCode }}</td><td>{{ j.sessionId ? 'S' + j.sessionId : '' }}</td><td>{{ j.userName }}</td><td><span class="badge" :class="cls(j.eventType)">{{ eventLabel(j.eventType) }}</span></td><td>{{ j.reference }}</td><td class="small">{{ j.description }}</td><td class="right num bold">{{ j.amount !== null ? fmt(j.amount) : '' }}</td></tr>
      <tr v-if="!rows.length"><td colspan="9" class="empty">Aucune opération sur la période</td></tr>
    </tbody></table></div>
</template>
