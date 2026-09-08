<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import { permissionLabel } from '../../utils/i18n'
import Modal from '../../components/common/Modal.vue'
const ui = useUiStore(); const { busy, run } = useBusy()
const rows = ref([]); const perms = ref([]); const edit = ref(null)
async function load() { try { [rows.value, perms.value] = await Promise.all([api.admin.roles(), api.admin.permissions()]) } catch (e) { ui.error(e.humanMessage) } }
onMounted(load)
function toggle(p) { const i = edit.value.permissions.indexOf(p); if (i >= 0) edit.value.permissions.splice(i, 1); else edit.value.permissions.push(p) }
async function save() { const r = await run(() => api.admin.saveRole(edit.value.id, edit.value), { success: 'Rôle enregistré' }); if (r) { edit.value = null; load() } }
async function remove(r) { if (!await ui.confirm({ title: 'Supprimer', message: `Supprimer le rôle ${r.name} ?`, okLabel: 'Supprimer', danger: true })) return; if (await run(() => api.admin.deleteRole(r.id), { success: 'Supprimé' })) load() }
</script>
<template>
  <div class="toolbar"><button class="btn primary" @click="edit={ code: '', name: '', permissions: [] }">+ Nouveau rôle</button><span class="muted small">Les permissions sont vérifiées côté serveur à chaque appel API.</span></div>
  <div class="grid-2">
    <div v-for="r in rows" :key="r.id" class="card">
      <div class="row between mb-8"><div><b style="font-size:17px">{{ r.name }}</b> <span class="badge">{{ r.code }}</span> <span class="badge info" v-if="r.systemRole">système</span><div class="tiny muted">{{ r.userCount }} utilisateur(s)</div></div><div class="row gap-4"><button class="btn sm" @click="edit={ ...r, permissions: [...r.permissions] }">Modifier</button><button class="btn sm danger" v-if="!r.systemRole" @click="remove(r)">✕</button></div></div>
      <div class="row wrap gap-4"><span v-for="p in r.permissions" :key="p" class="badge success">{{ permissionLabel(p) }}</span></div>
    </div>
  </div>
  <Modal v-if="edit" size="md" :title="edit.id ? 'Modifier le rôle ' + edit.name : 'Nouveau rôle'" @close="edit=null">
    <div class="form-grid mb-16"><div class="field"><label>Code</label><input class="input" v-model="edit.code" :disabled="edit.systemRole" /></div><div class="field"><label>Nom</label><input class="input" v-model="edit.name" /></div></div>
    <div class="perms"><label v-for="p in perms" :key="p" class="check" :style="{ opacity: edit.code==='ADMIN' ? .6 : 1 }"><input type="checkbox" :checked="edit.permissions.includes(p) || edit.code==='ADMIN'" :disabled="edit.code==='ADMIN'" @change="toggle(p)" /><span>{{ permissionLabel(p) }}<div class="tiny muted">{{ p }}</div></span></label></div>
    <template #foot><button class="btn lg" @click="edit=null">Annuler</button><button class="btn lg primary" :disabled="busy || !edit.name || !edit.code" @click="save">Enregistrer</button></template>
  </Modal>
</template>
<style scoped>.perms { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 4px 16px; }</style>
