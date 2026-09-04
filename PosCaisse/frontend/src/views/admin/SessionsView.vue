<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { fmt } from '../../utils/money'
import { fmtDateTime, isoDate, addDays, startOfDayIso, endOfDayIso } from '../../utils/dates'
import Modal from '../../components/common/Modal.vue'
import PeriodPicker from '../../components/common/PeriodPicker.vue'
const ui = useUiStore()
const from = ref(addDays(isoDate(), -6)); const to = ref(isoDate()); const rows = ref([]); const sel = ref(null); const summary = ref(null); const movements = ref([])
async function load() { try { rows.value = await api.registers.sessions({ from: startOfDayIso(from.value), to: endOfDayIso(to.value) }) } catch (e) { ui.error(e.humanMessage) } }
onMounted(load)
async function openSession(s) { sel.value = s; summary.value = null; try { [summary.value, movements.value] = await Promise.all([api.registers.summary(s.id), api.registers.movements(s.id)]) } catch (e) { ui.error(e.humanMessage) } }
</script>
<template>
  <div class="toolbar"><PeriodPicker v-model:from="from" v-model:to="to" @change="load" /></div>
  <div class="table-wrap"><table class="table">
    <thead><tr><th>#</th><th>Caisse</th><th>Caissier</th><th>Ouverture</th><th>Clôture</th><th class="right">Fond</th><th class="right">Espèces</th><th class="right">Carte</th><th class="right">Théorique</th><th class="right">Réel</th><th class="right">Écart</th><th class="right">Tickets</th><th class="right">CA</th><th>Statut</th></tr></thead>
    <tbody>
      <tr v-for="s in rows" :key="s.id" class="clickable" @click="openSession(s)">
        <td>S{{ s.id }}</td><td>{{ s.registerName }}</td><td>{{ s.openedByName }}</td><td>{{ fmtDateTime(s.openedAt) }}</td><td>{{ fmtDateTime(s.closedAt) }}</td>
        <td class="right num">{{ fmt(s.openingFloat) }}</td><td class="right num">{{ s.cashSales !== null ? fmt(s.cashSales) : '' }}</td><td class="right num">{{ s.cardSales !== null ? fmt(s.cardSales) : '' }}</td>
        <td class="right num">{{ s.expectedCash !== null ? fmt(s.expectedCash) : '' }}</td><td class="right num">{{ s.countedCash !== null ? fmt(s.countedCash) : '' }}</td>
        <td class="right num bold" :style="{ color: Number(s.cashDifference) < 0 ? 'var(--danger)' : Number(s.cashDifference) > 0 ? '#b45309' : 'inherit' }">{{ s.cashDifference !== null ? fmt(s.cashDifference) : '' }}</td>
        <td class="right num">{{ s.ticketsCount ?? '' }}</td><td class="right num">{{ s.revenue !== null ? fmt(s.revenue) : '' }}</td><td><span class="badge" :class="s.status==='OPEN' ? 'success' : ''">{{ s.status==='OPEN' ? 'Ouverte' : 'Clôturée' }}</span></td>
      </tr>
      <tr v-if="!rows.length"><td colspan="14" class="empty">Aucune session</td></tr>
    </tbody></table></div>
  <Modal v-if="sel" size="md" :title="`Session S${sel.id} — ${sel.registerName} · ${sel.openedByName}`" @close="sel=null">
    <div v-if="!summary" class="spinner"></div>
    <div v-else class="grid-2">
      <div class="card tight"><div class="card-title">Espèces</div>
        <div class="row between"><span>Fond initial</span><b class="num">{{ fmt(summary.openingFloat) }}</b></div><div class="row between"><span>Ventes espèces</span><b class="num">{{ fmt(summary.cashSales) }}</b></div>
        <div class="row between"><span>Remboursements espèces</span><b class="num">−{{ fmt(summary.cashRefunds) }}</b></div><div class="row between"><span>Entrées</span><b class="num">{{ fmt(summary.cashIn) }}</b></div><div class="row between"><span>Sorties</span><b class="num">−{{ fmt(summary.cashOut) }}</b></div>
        <div class="row between bold" style="font-size:18px;margin-top:6px"><span>Théorique</span><b class="num">{{ fmt(summary.expectedCash) }}</b></div>
        <template v-if="sel.status==='CLOSED'"><div class="row between"><span>Compté</span><b class="num">{{ fmt(sel.countedCash) }}</b></div><div class="row between bold"><span>Écart</span><b class="num">{{ fmt(sel.cashDifference) }}</b></div><div class="small muted" v-if="sel.closingNote">Note : {{ sel.closingNote }}</div></template>
      </div>
      <div class="card tight"><div class="card-title">Ventes</div>
        <div class="row between" v-for="(v,k) in summary.byMethod" :key="k"><span>{{ k }}</span><b class="num">{{ fmt(v) }}</b></div>
        <div class="row between"><span>Tickets</span><b>{{ summary.ticketsCount }}</b></div><div class="row between"><span>Annulations</span><b>{{ summary.cancellationsCount }}</b></div><div class="row between"><span>Remises</span><b class="num">{{ fmt(summary.discounts) }}</b></div>
        <div class="row between bold" style="font-size:18px;margin-top:6px"><span>CA</span><b class="num">{{ fmt(summary.revenue) }}</b></div>
      </div>
      <div class="card tight" style="grid-column:1/-1" v-if="movements.length"><div class="card-title">Mouvements de caisse</div>
        <div class="row between small" v-for="m in movements" :key="m.id"><span>{{ fmtDateTime(m.createdAt) }} · {{ m.userName }} · {{ m.reason }} {{ m.comment ? '— ' + m.comment : '' }}</span><b class="num" :style="{ color: m.type==='OUT' ? 'var(--danger)' : 'var(--success)' }">{{ m.type==='OUT' ? '−' : '+' }}{{ fmt(m.amount) }}</b></div>
      </div>
    </div>
  </Modal>
</template>
