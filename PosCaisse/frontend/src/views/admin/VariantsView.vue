<script setup>
/**
 * Variantes : les versions d'un même plat, avec leur prix.
 *
 * Une variante n'est pas une option. Le client ne commande pas « une pizza thon avec du
 * large » : il commande « une pizza thon large ». La valeur choisie porte donc un prix
 * complet et entre dans le nom imprimé, au lieu de s'ajouter en ligne de supplément.
 *
 * Les prix, eux, ne se règlent pas ici mais dans chaque fiche article : la même « Large »
 * ne vaut pas le même prix sur une pizza thon et sur une pizza fruits de mer.
 */
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import Modal from '../../components/common/Modal.vue'
import Icon from '../../components/common/Icon.vue'

const ui = useUiStore(); const { busy, run } = useBusy()
const rows = ref([]); const edit = ref(null); const dragId = ref(null)

async function load() { try { rows.value = await api.admin.variants() } catch (e) { ui.error(e) } }
onMounted(load)

function create() { edit.value = { name: '', namePosition: 'SUFFIX', active: true, values: [{ name: '', shortName: '', active: true }] } }
function open(v) { edit.value = { ...v, values: v.values.map(x => ({ ...x })) } }
function addValue() { edit.value.values.push({ name: '', shortName: '', active: true }) }

async function save() {
  const v = edit.value
  if (!v.values.some(x => x.name?.trim())) return ui.error('Une variante sans valeur ne sert à rien : ajoutez au moins « Petite » ou « Normale ».')
  const b = { ...v, values: v.values.filter(x => x.name?.trim()).map((x, i) => ({ ...x, sortOrder: i })) }
  const r = await run(() => api.admin.saveVariant(v.id, b), { success: 'Variante enregistrée' })
  if (r) { edit.value = null; load() }
}
async function remove(v) {
  if (!await ui.confirm({ title: 'Supprimer', message: `Supprimer « ${v.name} » ? Les articles qui l'utilisent perdront leurs versions ; les tickets déjà passés gardent les leurs.`, okLabel: 'Supprimer', danger: true })) return
  if (await run(() => api.admin.deleteVariant(v.id), { success: 'Supprimée' })) load()
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
  if (await run(() => api.admin.reorderVariants(rows.value.map(v => v.id)), { success: 'Ordre enregistré' })) load()
}
</script>

<template>
  <div class="toolbar">
    <button class="btn primary" @click="create">+ Nouvelle variante</button>
    <span class="muted small">{{ rows.length }} variante(s)</span>
    <span class="hint">Un article porte au plus une variante — les prix se règlent dans sa fiche</span>
  </div>

  <div class="table-wrap"><table class="table">
    <thead><tr><th class="ord">Ordre</th><th>Variante</th><th>Versions</th><th>Dans le nom</th><th>Active</th><th></th></tr></thead>
    <tbody>
      <tr v-for="(v, i) in rows" :key="v.id" class="drag" :class="{ dragging: dragId === v.id }" draggable="true"
          @dragstart="dragId = v.id" @dragover="onDragOver($event, i)" @drop.prevent="onDrop" @dragend="onDrop">
        <td class="ord"><span class="grip" aria-hidden="true"></span><b class="num">{{ i + 1 }}</b></td>
        <td><b>{{ v.name }}</b></td>
        <td>
          <span v-for="x in v.values" :key="x.id" class="val" :class="{ off: !x.active }">
            {{ x.name }}<em v-if="x.shortName"> · {{ x.shortName }}</em>
          </span>
        </td>
        <td class="exemple">
          <code v-if="v.namePosition === 'PREFIX'">{{ v.values[0]?.shortName || v.values[0]?.name || '…' }} Sandwich Thon</code>
          <code v-else>Pizza Thon {{ v.values[0]?.shortName || v.values[0]?.name || '…' }}</code>
        </td>
        <td><span class="badge" :class="v.active ? 'success' : 'danger'">{{ v.active ? 'Oui' : 'Non' }}</span></td>
        <td class="actions">
          <button class="btn sm" @click="open(v)">Modifier</button>
          <button class="btn sm danger" @click="remove(v)">✕</button>
        </td>
      </tr>
      <tr v-if="!rows.length"><td colspan="6" class="empty">Aucune variante. Un article garde alors son prix unique.</td></tr>
    </tbody>
  </table></div>

  <Modal v-if="edit" size="md" :title="edit.id ? 'Modifier la variante' : 'Nouvelle variante'" @close="edit = null">
    <div class="col gap-16">
      <div class="form-grid">
        <div class="field"><label>Nom</label><input class="input" v-model="edit.name" maxlength="60" autofocus placeholder="ex. Taille" /></div>
        <div class="field">
          <label>Place dans le nom</label>
          <select class="input" v-model="edit.namePosition">
            <option value="SUFFIX">Après — « Pizza Thon Large »</option>
            <option value="PREFIX">Avant — « 1/2 Sandwich Thon »</option>
          </select>
        </div>
      </div>
      <label class="check"><input type="checkbox" v-model="edit.active" /> Proposée dans les fiches article</label>

      <div>
        <div class="row between mb-8">
          <span class="eyebrow">Versions</span>
          <button class="btn sm" @click="addValue"><Icon name="plus" :size="15" />Ajouter</button>
        </div>
        <!-- Le nom court n'est pas un detail : le ticket fait 42 colonnes, et « Large »
             y coute cinq caracteres de plus que « L » sur chaque ligne. -->
        <div class="entetes"><span>Nom</span><span>Sur le ticket</span><span>Active</span><span></span></div>
        <div v-for="(x, i) in edit.values" :key="i" class="ligne">
          <input class="input" v-model="x.name" maxlength="60" placeholder="ex. Large" />
          <input class="input" v-model="x.shortName" maxlength="20" :placeholder="x.name || 'idem'" />
          <label class="check"><input type="checkbox" v-model="x.active" /></label>
          <button class="btn sm danger" :disabled="edit.values.length < 2" @click="edit.values.splice(i, 1)">✕</button>
        </div>
        <p class="tiny muted mt-8">
          Une version retirée ou désactivée est refusée si un article l'a pour valeur par défaut :
          il deviendrait invendable sans que personne ne l'apprenne.
        </p>
      </div>
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

.val {
  display: inline-block; margin: 2px 5px 2px 0; padding: 2px 9px; border-radius: 999px;
  font-size: 12.5px; background: var(--surface-2); border: 1px solid var(--line);
}
.val em { font-style: normal; color: var(--ink-3); }
.val.off { opacity: .5; text-decoration: line-through; }
.exemple code { font-size: 12px; color: var(--ink-3); }

.entetes, .ligne { display: grid; grid-template-columns: 1fr 1fr 64px 44px; gap: 8px; align-items: center; }
.entetes { margin-bottom: 5px; font-size: 11px; font-weight: 700; letter-spacing: .07em; text-transform: uppercase; color: var(--ink-3); }
.ligne + .ligne { margin-top: 7px; }
.ligne .check { justify-content: center; }
</style>
