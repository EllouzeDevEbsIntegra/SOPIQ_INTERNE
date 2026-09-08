<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import Modal from '../../components/common/Modal.vue'
const ui = useUiStore(); const { busy, run } = useBusy()
const rows = ref([]); const q = ref(''); const edit = ref(null)
async function load() { try { rows.value = await api.admin.customers(q.value) } catch (e) { ui.error(e.humanMessage) } }
onMounted(load)
async function save() { const r = await run(() => api.admin.saveCustomer(edit.value.id, edit.value), { success: 'Client enregistré' }); if (r) { edit.value = null; load() } }
</script>
<template>
  <div class="toolbar"><button class="btn primary" @click="edit={ name: '', phone: '', note: '' }">+ Nouveau client</button><input class="input" v-model="q" placeholder="Nom ou téléphone" @keyup.enter="load" /><button class="btn" @click="load">Rechercher</button></div>
  <div class="table-wrap"><table class="table"><thead><tr><th>Nom</th><th>Téléphone</th><th>Remarque</th><th></th></tr></thead>
    <tbody><tr v-for="c in rows" :key="c.id"><td><b>{{ c.name }}</b></td><td>{{ c.phone }}</td><td class="small">{{ c.note }}</td><td class="actions"><button class="btn sm" @click="edit={...c}">Modifier</button></td></tr><tr v-if="!rows.length"><td colspan="4" class="empty">Aucun client</td></tr></tbody></table></div>
  <Modal v-if="edit" :title="edit.id ? 'Modifier le client' : 'Nouveau client'" @close="edit=null">
    <div class="col gap-16"><div class="field"><label>Nom</label><input class="input" v-model="edit.name" autofocus /></div><div class="field"><label>Téléphone</label><input class="input" v-model="edit.phone" /></div><div class="field"><label>Remarque</label><input class="input" v-model="edit.note" /></div></div>
    <template #foot><button class="btn lg" @click="edit=null">Annuler</button><button class="btn lg primary" :disabled="busy || !edit.name" @click="save">Enregistrer</button></template>
  </Modal>
</template>
