<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import Modal from '../../components/common/Modal.vue'
const ui = useUiStore(); const { busy, run } = useBusy()
const rows = ref([]); const dests = ref([]); const edit = ref(null)
const COLORS = ['#f97316', '#eab308', '#ef4444', '#8b5cf6', '#0ea5e9', '#ec4899', '#22c55e', '#10b981', '#3b82f6', '#64748b', '#a16207', '#0f172a']
async function load() { try { rows.value = await api.catalog.categories() } catch (e) { ui.error(e.humanMessage) } }
onMounted(() => { load(); api.admin.destinations().then(d => { dests.value = d }).catch(() => {}) })
function create() { edit.value = { name: '', color: COLORS[rows.value.length % COLORS.length], icon: '', sortOrder: rows.value.length + 1, active: true, printDestinationId: null } }
async function save() { const r = await run(() => api.catalog.saveCategory(edit.value.id, edit.value), { success: 'Catégorie enregistrée' }); if (r) { edit.value = null; load() } }
async function remove(c) { if (!await ui.confirm({ title: 'Supprimer', message: `Supprimer la catégorie « ${c.name} » ?`, okLabel: 'Supprimer', danger: true })) return; if (await run(() => api.catalog.deleteCategory(c.id), { success: 'Supprimée' })) load() }
async function move(i, d) { const j = i + d; if (j < 0 || j >= rows.value.length) return; const a = rows.value.splice(i, 1)[0]; rows.value.splice(j, 0, a); await run(() => api.catalog.reorderCategories(rows.value.map(r => r.id))); load() }
</script>
<template>
  <div class="toolbar"><button class="btn primary" @click="create">+ Nouvelle catégorie</button><span class="muted small">Les flèches modifient l'ordre affiché sur le POS.</span></div>
  <div class="table-wrap"><table class="table">
    <thead><tr><th>Ordre</th><th>Catégorie</th><th>Icône</th><th>Couleur</th><th>Produits</th><th>Destination d'impression</th><th>Actif</th><th></th></tr></thead>
    <tbody><tr v-for="(c, i) in rows" :key="c.id">
      <td><button class="btn sm icon" @click="move(i,-1)">↑</button> <button class="btn sm icon" @click="move(i,1)">↓</button></td><td><b>{{ c.name }}</b></td><td style="font-size:22px">{{ c.icon }}</td><td><span class="color-dot" :style="{ background: c.color }"></span>{{ c.color }}</td><td>{{ c.productCount }}</td>
      <td>{{ dests.find(d => d.id===c.printDestinationId)?.name || '—' }}</td><td><span class="badge" :class="c.active ? 'success' : 'danger'">{{ c.active ? 'Oui' : 'Non' }}</span></td>
      <td class="actions"><button class="btn sm" @click="edit={...c}">Modifier</button> <button class="btn sm danger" @click="remove(c)">Supprimer</button></td></tr></tbody></table></div>
  <Modal v-if="edit" :title="edit.id ? 'Modifier la catégorie' : 'Nouvelle catégorie'" @close="edit=null">
    <div class="form-grid">
      <div class="field span-2"><label>Nom</label><input class="input" v-model="edit.name" autofocus /></div>
      <div class="field"><label>Icône (emoji)</label><input class="input" v-model="edit.icon" placeholder="🍔" /></div>
      <div class="field"><label>Ordre</label><input class="input" type="number" v-model.number="edit.sortOrder" /></div>
      <div class="field span-2"><label>Couleur</label><div class="row wrap gap-6"><button v-for="c in COLORS" :key="c" class="sw" :class="{ on: edit.color===c }" :style="{ background: c }" @click="edit.color=c"></button><input class="input" v-model="edit.color" style="width:120px" /></div></div>
      <div class="field"><label>Destination d'impression par défaut</label><select class="input" v-model="edit.printDestinationId"><option :value="null">— Aucune —</option><option v-for="d in dests.filter(d => d.kind==='PREP')" :key="d.id" :value="d.id">{{ d.name }}</option></select></div>
      <label class="check"><input type="checkbox" v-model="edit.active" /> Active (visible sur le POS)</label>
    </div>
    <template #foot><button class="btn lg" @click="edit=null">Annuler</button><button class="btn lg primary" :disabled="busy || !edit.name" @click="save">Enregistrer</button></template>
  </Modal>
</template>
<style scoped>.sw { width: 36px; height: 36px; border-radius: 10px; border: 3px solid transparent; } .sw.on { border-color: #0f172a; }</style>
