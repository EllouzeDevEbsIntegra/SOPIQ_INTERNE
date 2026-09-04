<script setup>
/**
 * Remarques de cuisine proposées au caissier sur une ligne de commande.
 * L'ordre se règle par glisser-déposer : c'est celui des touches en caisse.
 */
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import Modal from '../../components/common/Modal.vue'

const ui = useUiStore(); const { busy, run } = useBusy()
const rows = ref([]); const edit = ref(null); const dragId = ref(null)

async function load() { try { rows.value = await api.admin.kitchenNotes() } catch (e) { ui.error(e) } }
onMounted(load)

async function save() {
  const r = await run(() => api.admin.saveKitchenNote(edit.value.id, edit.value), { success: 'Remarque enregistrée' })
  if (r) { edit.value = null; load() }
}
async function remove(n) {
  if (!await ui.confirm({ title: 'Supprimer', message: `Supprimer « ${n.label} » ? Les tickets déjà passés gardent leur texte.`, okLabel: 'Supprimer', danger: true })) return
  if (await run(() => api.admin.deleteKitchenNote(n.id), { success: 'Supprimée' })) load()
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
  if (await run(() => api.admin.reorderKitchenNotes(rows.value.map(n => n.id)), { success: 'Ordre enregistré' })) load()
}
</script>

<template>
  <div class="toolbar">
    <button class="btn primary" @click="edit = { label: '', active: true }">+ Nouvelle remarque</button>
    <span class="muted small">{{ rows.length }} remarque(s)</span>
    <span class="hint">Glissez une ligne pour changer l'ordre des touches en caisse</span>
    <span class="grow"></span>
    <span class="muted small">Une remarque désactivée n'est plus proposée ; les tickets déjà passés gardent leur texte.</span>
  </div>

  <div class="table-wrap"><table class="table">
    <thead><tr><th class="ord">Ordre</th><th>Remarque</th><th>Active</th><th></th></tr></thead>
    <tbody>
      <tr v-for="(n, i) in rows" :key="n.id" class="drag" :class="{ dragging: dragId === n.id }" draggable="true"
          @dragstart="dragId = n.id" @dragover="onDragOver($event, i)" @drop.prevent="onDrop" @dragend="onDrop">
        <td class="ord"><span class="grip" aria-hidden="true"></span><b class="num">{{ i + 1 }}</b></td>
        <td><b>{{ n.label }}</b></td>
        <td><span class="badge" :class="n.active ? 'success' : 'danger'">{{ n.active ? 'Oui' : 'Non' }}</span></td>
        <td class="actions">
          <button class="btn sm" @click="edit = { ...n }">Modifier</button>
          <button class="btn sm danger" @click="remove(n)">✕</button>
        </td>
      </tr>
      <tr v-if="!rows.length"><td colspan="4" class="empty">Aucune remarque. Le caissier pourra toujours écrire un texte libre.</td></tr>
    </tbody>
  </table></div>

  <Modal v-if="edit" :title="edit.id ? 'Modifier la remarque' : 'Nouvelle remarque'" @close="edit = null">
    <div class="col gap-16">
      <div class="field"><label>Texte</label><input class="input" v-model="edit.label" maxlength="80" autofocus placeholder="ex. sans oignon" @keyup.enter="save" /></div>
      <label class="check"><input type="checkbox" v-model="edit.active" /> Proposée en caisse</label>
    </div>
    <template #foot>
      <button class="btn lg" @click="edit = null">Annuler</button>
      <button class="btn lg primary" :disabled="busy || !edit.label?.trim()" @click="save">Enregistrer</button>
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
