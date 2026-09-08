<script setup>
/** Livreurs : la liste où le caissier viendra piocher, et dont chacun a un compte. */
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import Modal from '../../components/common/Modal.vue'
const ui = useUiStore(); const { busy, run } = useBusy()
const rows = ref([]); const q = ref(''); const edit = ref(null)
async function load() { try { rows.value = await api.admin.couriers(q.value) } catch (e) { ui.error(e.humanMessage) } }
onMounted(load)
async function save() { const r = await run(() => api.admin.saveCourier(edit.value.id, edit.value), { success: 'Livreur enregistré' }); if (r) { edit.value = null; load() } }
</script>
<template>
  <div class="toolbar">
    <button class="btn primary" @click="edit={ name: '', phone: '', note: '', active: true }">+ Nouveau livreur</button>
    <input class="input" v-model="q" placeholder="Nom ou téléphone" @keyup.enter="load" /><button class="btn" @click="load">Rechercher</button>
    <span class="grow"></span>
    <span class="muted small">Un livreur désactivé n'apparaît plus en caisse ; son compte et son historique restent consultables.</span>
  </div>
  <div class="table-wrap"><table class="table"><thead><tr><th>Nom</th><th>Téléphone</th><th>Remarque</th><th>Actif</th><th></th></tr></thead>
    <tbody>
      <tr v-for="c in rows" :key="c.id"><td><b>{{ c.name }}</b></td><td>{{ c.phone }}</td><td class="small">{{ c.note }}</td>
        <td><span class="badge" :class="c.active ? 'success' : 'danger'">{{ c.active ? 'Oui' : 'Non' }}</span></td>
        <td class="actions"><button class="btn sm" @click="edit={...c}">Modifier</button></td></tr>
      <tr v-if="!rows.length"><td colspan="5" class="empty">Aucun livreur</td></tr>
    </tbody></table></div>
  <Modal v-if="edit" :title="edit.id ? 'Modifier le livreur' : 'Nouveau livreur'" @close="edit=null">
    <div class="col gap-16">
      <div class="field"><label>Nom</label><input class="input" v-model="edit.name" autofocus /></div>
      <div class="field"><label>Téléphone</label><input class="input" v-model="edit.phone" /></div>
      <div class="field"><label>Remarque</label><input class="input" v-model="edit.note" /></div>
      <label class="check"><input type="checkbox" v-model="edit.active" /> Actif</label>
    </div>
    <template #foot><button class="btn lg" @click="edit=null">Annuler</button><button class="btn lg primary" :disabled="busy || !edit.name" @click="save">Enregistrer</button></template>
  </Modal>
</template>
