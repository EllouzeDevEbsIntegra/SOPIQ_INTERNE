<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useCatalogStore } from '../../stores/catalog'
import { useBusy } from '../../composables/useApi'
import { t } from '../../utils/i18n'
import Modal from '../../components/common/Modal.vue'
const ui = useUiStore(); const catalog = useCatalogStore(); const { busy, run } = useBusy()
const rows = ref([]); const edit = ref(null); const kinds = ['CASH', 'CARD', 'CHECK', 'MEAL_VOUCHER', 'OTHER']
async function load() { try { rows.value = await api.catalog.paymentMethods() } catch (e) { ui.error(e.humanMessage) } }
onMounted(load)
async function save() { const r = await run(() => api.catalog.savePaymentMethod(edit.value.id, edit.value), { success: 'Moyen de paiement enregistré' }); if (r) { edit.value = null; load(); catalog.load(true).catch(() => {}) } }
</script>
<template>
  <div class="toolbar"><button class="btn primary" @click="edit={ code: '', name: '', kind: 'OTHER', opensDrawer: false, sortOrder: rows.length + 1, active: true }">+ Nouveau moyen de paiement</button></div>
  <div class="table-wrap"><table class="table"><thead><tr><th>Ordre</th><th>Code</th><th>Nom</th><th>Type</th><th>Ouvre le tiroir</th><th>Actif</th><th></th></tr></thead>
    <tbody><tr v-for="m in rows" :key="m.id"><td>{{ m.sortOrder }}</td><td>{{ m.code }}</td><td><b>{{ m.name }}</b></td><td>{{ t('paymentKind', m.kind) }}</td><td>{{ m.opensDrawer ? '✓' : '—' }}</td><td><span class="badge" :class="m.active ? 'success' : 'danger'">{{ m.active ? 'Oui' : 'Non' }}</span></td><td class="actions"><button class="btn sm" @click="edit={...m}">Modifier</button></td></tr></tbody></table></div>
  <Modal v-if="edit" :title="edit.id ? 'Modifier' : 'Nouveau moyen de paiement'" @close="edit=null">
    <div class="form-grid"><div class="field"><label>Code</label><input class="input" v-model="edit.code" /></div><div class="field"><label>Nom</label><input class="input" v-model="edit.name" /></div><div class="field"><label>Type</label><select class="input" v-model="edit.kind"><option v-for="k in kinds" :key="k" :value="k">{{ t('paymentKind', k) }}</option></select></div><div class="field"><label>Ordre</label><input class="input" type="number" v-model.number="edit.sortOrder" /></div><label class="check"><input type="checkbox" v-model="edit.opensDrawer" /> Ouvre le tiroir-caisse</label><label class="check"><input type="checkbox" v-model="edit.active" /> Actif</label></div>
    <template #foot><button class="btn lg" @click="edit=null">Annuler</button><button class="btn lg primary" :disabled="busy || !edit.name || !edit.code" @click="save">Enregistrer</button></template>
  </Modal>
</template>
