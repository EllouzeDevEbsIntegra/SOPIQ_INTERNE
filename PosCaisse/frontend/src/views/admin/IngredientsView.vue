<script setup>
/**
 * Ingrédients composant le nom des articles : « Omelette », « Thon », « Salami ».
 *
 * Ils ne se vendent pas et ne portent pas de prix — pour un supplément payant, ce sont
 * les options qui s'appliquent. Ils servent à composer un nom sans le retaper, et à
 * retrouver les articles qui les contiennent.
 *
 * L'ordre se règle par glisser-déposer : c'est celui des touches dans la fiche article.
 */
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import Modal from '../../components/common/Modal.vue'

const ui = useUiStore(); const { busy, run } = useBusy()
const rows = ref([]); const edit = ref(null); const dragId = ref(null)

async function load() { try { rows.value = await api.admin.ingredients() } catch (e) { ui.error(e) } }
onMounted(load)

async function save() {
  const r = await run(() => api.admin.saveIngredient(edit.value.id, edit.value), { success: 'Ingrédient enregistré' })
  if (r) { edit.value = null; load() }
}
async function remove(n) {
  if (!await ui.confirm({ title: 'Supprimer', message: `Supprimer « ${n.name} » ? Les articles gardent leur nom, mais on ne pourra plus les retrouver par cet ingrédient.`, okLabel: 'Supprimer', danger: true })) return
  if (await run(() => api.admin.deleteIngredient(n.id), { success: 'Supprimé' })) load()
}

function onDragOver(e, i) {
  if (dragId.value === null) return
  e.preventDefault()
  const from = rows.value.findIndex(x => x.id === dragId.value)
  if (from < 0 || from === i) return
  const seq = rows.value.slice()
  const [item] = seq.splice(from, 1)
  seq.splice(i, 0, item)
  rows.value = seq
}
async function onDrop() {
  if (dragId.value === null) return
  dragId.value = null
  if (await run(() => api.admin.reorderIngredients(rows.value.map(n => n.id)), { success: 'Ordre enregistré' })) load()
}
</script>

<template>
  <div class="toolbar">
    <button class="btn primary" @click="edit = { name: '', active: true }">+ Nouvel ingrédient</button>
    <span class="muted small">{{ rows.length }} ingrédient(s)</span>
    <span class="hint">Glissez une ligne pour changer l'ordre des touches dans la fiche article</span>
    <span class="grow"></span>
    <span class="muted small">Un ingrédient désactivé n'est plus proposé ; les articles déjà nommés gardent leur nom.</span>
  </div>

  <div class="table-wrap"><table class="table">
    <thead><tr><th class="ord">Ordre</th><th>Ingrédient</th><th>Active</th><th></th></tr></thead>
    <tbody>
      <tr v-for="(n, i) in rows" :key="n.id" class="drag" :class="{ dragging: dragId === n.id }" draggable="true"
          @dragstart="dragId = n.id" @dragover="onDragOver($event, i)" @drop.prevent="onDrop" @dragend="onDrop">
        <td class="ord"><span class="grip" aria-hidden="true"></span><b class="num">{{ i + 1 }}</b></td>
        <td><b>{{ n.name }}</b></td>
        <td><span class="badge" :class="n.active ? 'success' : 'danger'">{{ n.active ? 'Oui' : 'Non' }}</span></td>
        <td class="actions">
          <button class="btn sm" @click="edit = { ...n }">Modifier</button>
          <button class="btn sm danger" @click="remove(n)">✕</button>
        </td>
      </tr>
      <tr v-if="!rows.length"><td colspan="4" class="empty">Aucun ingrédient. Le nom des articles reste saisissable à la main.</td></tr>
    </tbody>
  </table></div>

  <Modal v-if="edit" :title="edit.id ? 'Modifier l\'ingrédient' : 'Nouvel ingrédient'" @close="edit = null">
    <div class="col gap-16">
      <div class="field"><label>Nom</label><input class="input" v-model="edit.name" maxlength="60" autofocus placeholder="ex. Thon" @keyup.enter="save" /></div>
      <label class="check"><input type="checkbox" v-model="edit.active" /> Proposé dans la fiche article</label>
    </div>
    <template #foot>
      <button class="btn lg" @click="edit = null">Annuler</button>
      <button class="btn lg primary" :disabled="busy || !edit.name?.trim()" @click="save">Enregistrer</button>
    </template>
  </Modal>
</template>

<style scoped>
.hint {
  display: inline-flex; padding: 5px 11px; border-radius: 999px; font-size: 12px;
  background: var(--surface-2); color: var(--ink-3); border: 1px dashed var(--line-2);
}
.ord { width: 74px; white-space: nowrap; }
.ord b { font-size: 13px; font-weight: 700; color: var(--ink-2); }
.grip {
  display: inline-block; width: 9px; height: 14px; margin-right: 8px; vertical-align: -2px;
  background-image: radial-gradient(circle, var(--ink-4) 1.1px, transparent 1.2px);
  background-size: 4.5px 4.5px; opacity: .85;
}
tr.drag { cursor: grab; }
tr.drag:hover { background: var(--surface-2); }
tr.dragging { opacity: .45; cursor: grabbing; background: var(--brand-soft); }
</style>
