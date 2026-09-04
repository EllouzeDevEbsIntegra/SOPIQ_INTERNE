<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import { fmt } from '../../utils/money'
import { fmtDateTime, fmtDate, isoDate } from '../../utils/dates'
const ui = useUiStore(); const { busy, run } = useBusy()
const pos = ref([]); const posId = ref(''); const date = ref(isoDate()); const preview = ref(null); const note = ref(''); const history = ref([]); const tab = ref('today')
async function load() { if (!posId.value) return; try { preview.value = await api.registers.closurePreview(posId.value, date.value) } catch (e) { ui.error(e.humanMessage) } }
async function loadHistory() { try { history.value = await api.registers.closures() } catch { /* ignore */ } }
onMounted(async () => { try { pos.value = await api.admin.pointsOfSale(); posId.value = pos.value[0]?.id || '' } catch (e) { ui.error(e.humanMessage) } load(); loadHistory() })
async function close() {
  if (!await ui.confirm({ title: 'Clôture journalière', message: `Clôturer la journée du ${fmtDate(date.value)} ?\nCA : ${fmt(preview.value.revenue, true)} · ${preview.value.ticketsCount} tickets`, okLabel: 'Clôturer' })) return
  const r = await run(() => api.registers.dailyClose({ pointOfSaleId: posId.value, businessDate: date.value, note: note.value || null }), { success: 'Journée clôturée' })
  if (r) { load(); loadHistory() }
}
</script>
<template>
  <div class="tabs"><button :class="{ on: tab==='today' }" @click="tab='today'">Clôturer une journée</button><button :class="{ on: tab==='history' }" @click="tab='history'">Historique ({{ history.length }})</button></div>
  <template v-if="tab==='today'">
    <div class="toolbar"><select class="input" v-model="posId" @change="load"><option v-for="p in pos" :key="p.id" :value="p.id">{{ p.name }}</option></select><input class="input" type="date" v-model="date" @change="load" /><button class="btn sm" @click="load">↻</button></div>
    <template v-if="preview">
      <div v-if="preview.alreadyClosed" class="badge success mb-16" style="font-size:14px;padding:8px 14px">✓ Journée déjà clôturée</div>
      <div v-else-if="preview.openSessions" class="badge warning mb-16" style="font-size:14px;padding:8px 14px">⚠ {{ preview.openSessions }} caisse(s) encore ouverte(s) — clôturez-les avant la clôture journalière</div>
      <div class="grid-kpi mb-16">
        <div class="kpi"><span class="label">CA</span><span class="value num">{{ fmt(preview.revenue, true) }}</span></div><div class="kpi"><span class="label">Tickets</span><span class="value num">{{ preview.ticketsCount }}</span><span class="sub">panier moyen {{ fmt(preview.averageTicket) }}</span></div>
        <div class="kpi"><span class="label">Espèces</span><span class="value num">{{ fmt(preview.cashTotal) }}</span></div><div class="kpi"><span class="label">Carte</span><span class="value num">{{ fmt(preview.cardTotal) }}</span></div><div class="kpi"><span class="label">Autres</span><span class="value num">{{ fmt(preview.otherTotal) }}</span></div>
        <div class="kpi"><span class="label">Remises</span><span class="value num">{{ fmt(preview.discountsTotal) }}</span></div><div class="kpi"><span class="label">Annulations</span><span class="value num">{{ preview.cancellationsCount }}</span><span class="sub">{{ fmt(preview.cancellationsTotal) }}</span></div>
        <div class="kpi"><span class="label">Remboursements</span><span class="value num">{{ fmt(preview.refundsTotal) }}</span></div><div class="kpi"><span class="label">Entrées / sorties</span><span class="value num">{{ fmt(preview.cashIn) }} / {{ fmt(preview.cashOut) }}</span></div>
        <div class="kpi" :style="{ background: Number(preview.cashDifference)===0 ? '' : 'var(--danger-soft)' }"><span class="label">Écarts de caisse</span><span class="value num">{{ fmt(preview.cashDifference) }}</span></div>
      </div>
      <div class="grid-2 mb-16">
        <div class="card"><div class="card-title">Par caisse</div><div class="row between" v-for="r in preview.byRegister" :key="r.name"><span>{{ r.name }} <span class="muted small">({{ r.tickets }} tickets)</span></span><b class="num">{{ fmt(r.amount) }}</b></div><div v-if="!preview.byRegister.length" class="muted">—</div></div>
        <div class="card"><div class="card-title">Par caissier</div><div class="row between" v-for="r in preview.byCashier" :key="r.name"><span>{{ r.name }} <span class="muted small">({{ r.tickets }} tickets)</span></span><b class="num">{{ fmt(r.amount) }}</b></div><div v-if="!preview.byCashier.length" class="muted">—</div></div>
        <div class="card"><div class="card-title">Par moyen de paiement</div><div class="row between" v-for="r in preview.byMethod" :key="r.name"><span>{{ r.name }}</span><b class="num">{{ fmt(r.amount) }}</b></div><div v-if="!preview.byMethod.length" class="muted">—</div></div>
        <div class="card"><div class="card-title">Sessions de la journée</div><div class="row between small" v-for="s in preview.sessions" :key="s.id"><span>S{{ s.id }} {{ s.registerName }} · {{ s.openedByName }} <span class="badge" :class="s.status==='OPEN' ? 'success' : ''">{{ s.status==='OPEN' ? 'ouverte' : 'clôturée' }}</span></span><b class="num">écart {{ s.cashDifference !== null ? fmt(s.cashDifference) : '—' }}</b></div><div v-if="!preview.sessions.length" class="muted">Aucune session</div></div>
      </div>
      <div class="card" v-if="!preview.alreadyClosed"><div class="row gap-8 wrap"><input class="input grow" v-model="note" placeholder="Commentaire de clôture (facultatif)" /><button class="btn primary lg" :disabled="busy || preview.openSessions > 0" @click="close">CLÔTURER LA JOURNÉE DU {{ fmtDate(date) }}</button></div></div>
    </template>
  </template>
  <div v-else class="table-wrap"><table class="table">
    <thead><tr><th>Date</th><th>Point de vente</th><th>Clôturé par</th><th>Le</th><th class="right">CA</th><th class="right">Tickets</th><th class="right">Panier moyen</th><th class="right">Espèces</th><th class="right">Carte</th><th class="right">Autres</th><th class="right">Remises</th><th class="right">Annul.</th><th class="right">Remb.</th><th class="right">Écarts</th><th>Note</th></tr></thead>
    <tbody><tr v-for="c in history" :key="c.id"><td><b>{{ fmtDate(c.businessDate) }}</b></td><td>{{ c.pointOfSaleName }}</td><td>{{ c.closedByName }}</td><td>{{ fmtDateTime(c.closedAt) }}</td><td class="right num bold">{{ fmt(c.revenue) }}</td><td class="right num">{{ c.ticketsCount }}</td><td class="right num">{{ fmt(c.averageTicket) }}</td><td class="right num">{{ fmt(c.cashTotal) }}</td><td class="right num">{{ fmt(c.cardTotal) }}</td><td class="right num">{{ fmt(c.otherTotal) }}</td><td class="right num">{{ fmt(c.discountsTotal) }}</td><td class="right num">{{ c.cancellationsCount }}</td><td class="right num">{{ fmt(c.refundsTotal) }}</td><td class="right num">{{ fmt(c.cashDifference) }}</td><td class="small">{{ c.note }}</td></tr>
    <tr v-if="!history.length"><td colspan="15" class="empty">Aucune clôture</td></tr></tbody></table></div>
</template>
