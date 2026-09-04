<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import { fmt } from '../../utils/money'
import Modal from '../../components/common/Modal.vue'
const ui = useUiStore(); const { busy, run } = useBusy()
const rows = ref([]); const edit = ref(null)
async function load() { try { rows.value = await api.catalog.modifiers() } catch (e) { ui.error(e.humanMessage) } }
onMounted(load)
function create() { edit.value = { name: '', required: false, multiple: true, minSelect: 0, maxSelect: 0, sortOrder: rows.value.length + 1, active: true, modifiers: [{ name: '', priceDelta: 0, active: true }] } }
function open(g) { edit.value = JSON.parse(JSON.stringify(g)) }
async function save() {
  const b = { ...edit.value, modifiers: edit.value.modifiers.filter(m => m.name.trim()).map((m, i) => ({ id: m.id, name: m.name.trim(), priceDelta: Number(m.priceDelta) || 0, sortOrder: i, active: m.active !== false })) }
  const r = await run(() => api.catalog.saveModifier(edit.value.id, b), { success: 'Groupe enregistré' }); if (r) { edit.value = null; load() }
}
async function remove(g) { if (!await ui.confirm({ title: 'Supprimer', message: `Supprimer « ${g.name} » ?`, okLabel: 'Supprimer', danger: true })) return; if (await run(() => api.catalog.deleteModifier(g.id), { success: 'Supprimé' })) load() }
</script>
<template>
  <div class="toolbar"><button class="btn primary" @click="create">+ Nouveau groupe d'options</button><span class="muted small">Ex. « Suppléments burger », « Taille pizza ». Les groupes sont ensuite associés aux produits.</span></div>
  <div class="grid-2">
    <div v-for="g in rows" :key="g.id" class="card">
      <div class="row between mb-8"><div><b style="font-size:17px">{{ g.name }}</b><div class="row gap-6 mt-8"><span class="badge" :class="g.required ? 'accent' : ''">{{ g.required ? 'Obligatoire' : 'Facultatif' }}</span><span class="badge">{{ g.multiple ? 'Choix multiple' : 'Choix unique' }}</span><span class="badge" v-if="g.minSelect || g.maxSelect">min {{ g.minSelect }} · max {{ g.maxSelect || '∞' }}</span><span class="badge danger" v-if="!g.active">Inactif</span></div></div><div class="row gap-4"><button class="btn sm" @click="open(g)">Modifier</button><button class="btn sm danger" @click="remove(g)">✕</button></div></div>
      <div class="row wrap gap-6"><span v-for="m in g.modifiers" :key="m.id" class="badge" :class="{ danger: !m.active }">{{ m.name }}<span v-if="Number(m.priceDelta)"> +{{ fmt(m.priceDelta) }}</span></span></div>
    </div>
  </div>
  <Modal v-if="edit" size="md" :title="edit.id ? 'Modifier le groupe' : 'Nouveau groupe'" @close="edit=null">
    <div class="form-grid">
      <div class="field span-2"><label>Nom du groupe</label><input class="input" v-model="edit.name" autofocus /></div>
      <label class="check"><input type="checkbox" v-model="edit.required" /> Choix obligatoire</label>
      <label class="check"><input type="checkbox" v-model="edit.multiple" /> Choix multiple</label>
      <div class="field"><label>Minimum</label><input class="input" type="number" min="0" v-model.number="edit.minSelect" /></div>
      <div class="field"><label>Maximum (0 = illimité)</label><input class="input" type="number" min="0" v-model.number="edit.maxSelect" :disabled="!edit.multiple" /></div>
      <label class="check"><input type="checkbox" v-model="edit.active" /> Actif</label>
    </div>
    <div class="section-title">Options</div>
    <div class="col gap-6">
      <div v-for="(m, i) in edit.modifiers" :key="i" class="row gap-6"><input class="input grow" v-model="m.name" placeholder="Nom de l'option" /><input class="input" v-model="m.priceDelta" inputmode="decimal" placeholder="Supplément" style="width:130px" /><label class="check small"><input type="checkbox" v-model="m.active" />Actif</label><button class="btn sm icon danger" @click="edit.modifiers.splice(i,1)">✕</button></div>
      <button class="btn sm soft" @click="edit.modifiers.push({ name: '', priceDelta: 0, active: true })">+ Ajouter une option</button>
    </div>
    <template #foot><button class="btn lg" @click="edit=null">Annuler</button><button class="btn lg primary" :disabled="busy || !edit.name" @click="save">Enregistrer</button></template>
  </Modal>
</template>
