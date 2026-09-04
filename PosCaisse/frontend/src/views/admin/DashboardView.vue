<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { fmt } from '../../utils/money'
import { isoDate } from '../../utils/dates'
import { serviceModeLabel } from '../../utils/i18n'
import BarChart from '../../components/common/BarChart.vue'
import PeriodPicker from '../../components/common/PeriodPicker.vue'
const ui = useUiStore()
const from = ref(isoDate()); const to = ref(isoDate()); const posId = ref(''); const d = ref(null); const loading = ref(false); const pos = ref([])
async function load() { loading.value = true; try { d.value = await api.reports.dashboard({ from: from.value, to: to.value, posId: posId.value || undefined }) } catch (e) { ui.error(e.humanMessage) } finally { loading.value = false } }
onMounted(() => { load(); api.admin.pointsOfSale().then(p => { pos.value = p }).catch(() => {}) })
const hours = () => { const map = Object.fromEntries((d.value?.byHour || []).map(h => [h.hour, h])); const out = []; for (let h = 6; h <= 23; h++) out.push({ label: h + 'h', value: map[h]?.revenue || 0 }); return out }
</script>
<template>
  <div class="toolbar"><PeriodPicker v-model:from="from" v-model:to="to" @change="load" /><select class="input" v-model="posId" @change="load" v-if="pos.length > 1"><option value="">Tous points de vente</option><option v-for="p in pos" :key="p.id" :value="p.id">{{ p.name }}</option></select><button class="btn sm" @click="load">↻</button></div>
  <div v-if="loading && !d" class="spinner"></div>
  <template v-if="d">
    <div class="grid-kpi mb-16">
      <div class="kpi"><span class="label">Chiffre d'affaires</span><span class="value num">{{ fmt(d.kpi.revenue, true) }}</span><span class="sub">net des remboursements</span></div>
      <div class="kpi"><span class="label">Tickets</span><span class="value num">{{ d.kpi.tickets }}</span><span class="sub">{{ Number(d.kpi.items) }} articles</span></div>
      <div class="kpi"><span class="label">Panier moyen</span><span class="value num">{{ fmt(d.kpi.average_ticket, true) }}</span></div>
      <div class="kpi"><span class="label">Remises</span><span class="value num">{{ fmt(d.kpi.discounts) }}</span></div>
      <div class="kpi"><span class="label">Annulations</span><span class="value num">{{ d.kpi.cancellations }}</span><span class="sub">{{ fmt(d.kpi.cancellations_total) }}</span></div>
      <div class="kpi"><span class="label">Remboursements</span><span class="value num">{{ fmt(d.kpi.refunds) }}</span></div>
    </div>
    <div class="grid-2">
      <div class="card" style="grid-column: 1 / -1"><div class="card-title">CA heure par heure</div><BarChart :data="hours()" vertical :max="24" /></div>
      <div class="card" v-if="d.byDay.length > 1"><div class="card-title">CA par jour</div><BarChart :data="d.byDay.map(x => ({ label: String(x.day).slice(5), value: x.revenue }))" vertical :max="31" /></div>
      <div class="card"><div class="card-title">Top produits (quantité)</div><BarChart :data="d.topProducts" label-key="name" value-key="quantity" :money="false" color="#0ea5e9" /></div>
      <div class="card"><div class="card-title">Ventes par catégorie</div><BarChart :data="d.byCategory" label-key="name" value-key="revenue" color-key="color" /></div>
      <div class="card"><div class="card-title">Ventes par caissier</div><BarChart :data="d.byCashier" label-key="name" value-key="revenue" color="#8b5cf6" /></div>
      <div class="card"><div class="card-title">Moyens de paiement</div><BarChart :data="d.byPaymentMethod" label-key="name" value-key="amount" color="#16a34a" /></div>
      <div class="card"><div class="card-title">Par caisse</div><BarChart :data="d.byRegister" label-key="name" value-key="revenue" color="#f59e0b" /></div>
      <div class="card"><div class="card-title">Mode de service</div><BarChart :data="d.byServiceMode.map(x => ({ label: serviceModeLabel(x.mode), value: x.revenue }))" color="#ec4899" /></div>
    </div>
  </template>
</template>
