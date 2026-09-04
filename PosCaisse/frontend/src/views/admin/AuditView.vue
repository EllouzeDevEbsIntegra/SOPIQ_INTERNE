<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { fmtDateTime, isoDate, addDays, startOfDayIso, endOfDayIso } from '../../utils/dates'
import PeriodPicker from '../../components/common/PeriodPicker.vue'
const ui = useUiStore()
const from = ref(addDays(isoDate(), -6)); const to = ref(isoDate()); const action = ref(''); const rows = ref([])
async function load() { try { rows.value = await api.admin.audit({ from: startOfDayIso(from.value), to: endOfDayIso(to.value), action: action.value || undefined, limit: 1000 }) } catch (e) { ui.error(e.humanMessage) } }
onMounted(load)
const cls = (a) => /CANCEL|DELETE|REFUND|FAILED/.test(a) ? 'danger' : /SALE|LOGIN|OPEN/.test(a) ? 'success' : /DISCOUNT|PRICE|SETTINGS|PIN/.test(a) ? 'warning' : ''
</script>
<template>
  <div class="toolbar"><PeriodPicker v-model:from="from" v-model:to="to" @change="load" /><input class="input" v-model="action" placeholder="Action (ex. SALE, REFUND)" @keyup.enter="load" /><button class="btn" @click="load">Filtrer</button></div>
  <div class="table-wrap"><table class="table"><thead><tr><th>Date</th><th>Utilisateur</th><th>Action</th><th>Entité</th><th>ID</th><th>Détails</th></tr></thead>
    <tbody><tr v-for="a in rows" :key="a.id"><td class="small">{{ fmtDateTime(a.createdAt) }}</td><td>{{ a.username || '—' }}</td><td><span class="badge" :class="cls(a.action)">{{ a.action }}</span></td><td>{{ a.entityType }}</td><td>{{ a.entityId }}</td><td class="small">{{ a.details }}</td></tr><tr v-if="!rows.length"><td colspan="6" class="empty">Aucune entrée</td></tr></tbody></table></div>
</template>
