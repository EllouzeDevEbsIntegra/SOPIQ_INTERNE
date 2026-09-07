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

const valeurNeuve = () => ({ name: '', shortName: '', active: true, stockManaged: false, stockStep: 1, stockSourceId: null, stockMode: 'non' })
const avecMode = (x) => ({ ...valeurNeuve(), ...x, stockMode: x.stockManaged ? 'propre' : (x.stockSourceId ? 'lie' : 'non') })
function create() { edit.value = { name: '', namePosition: 'SUFFIX', active: true, values: [valeurNeuve()] } }
function open(v) { edit.value = { ...v, values: v.values.map(avecMode) } }
function addValue() { edit.value.values.push(valeurNeuve()) }

/*
    Le suivi de stock d'une version, en trois etats qui s'excluent.

    « Compteur propre » et « tire sur une autre » ne peuvent pas coexister : ce serait
    retirer deux fois la meme pate. Un seul reglage a trois positions le dit mieux que
    deux cases a cocher qu'il faudrait apprendre a ne pas cocher ensemble.

    L'etat est PORTE, pas deduit. Deduit de stockSourceId, « tire sur une autre » ne
    tenait pas une seconde : on choisissait la position, la source etait encore vide,
    donc le reglage retombait sur « non suivi » avant meme d'avoir pu designer la
    version - et le choix de la version n'apparaissait jamais.
*/
const modeStock = (x) => x.stockMode || (x.stockManaged ? 'propre' : (x.stockSourceId ? 'lie' : 'non'))
function setModeStock(x, mode) {
  x.stockMode = mode
  x.stockManaged = mode === 'propre'
  if (mode !== 'lie') x.stockSourceId = null
  if (mode === 'non') x.stockStep = 1
  if (mode === 'lie' && !(Number(x.stockStep) > 1)) x.stockStep = 2
}
/*
    Toutes les autres versions de l'axe sont proposees, et non les seules qui portent
    deja un compteur : sinon l'ordre des gestes devenait un piege - brancher « Double
    Normale » avant d'avoir coche « Normale » ne proposait rien du tout, sans dire
    pourquoi. Designer une version lui donne donc son compteur.
*/
const sources = (x) => (edit.value?.values || []).filter(v => v !== x && v.name?.trim())
function setSource(x, id) {
  x.stockSourceId = id ? Number(id) : null
  const s = (edit.value?.values || []).find(v => v.id === x.stockSourceId)
  if (s && !s.stockManaged) setModeStock(s, 'propre')
}
const nomSource = (x) => (edit.value?.values || []).find(v => v.id === x.stockSourceId)?.name || ''

async function save() {
  const v = edit.value
  if (!v.values.some(x => x.name?.trim())) return ui.error('Une variante sans valeur ne sert à rien : ajoutez au moins « Petite » ou « Normale ».')
  const orphelin = v.values.find(x => x.name?.trim() && modeStock(x) === 'lie' && !x.stockSourceId)
  if (orphelin) return ui.error(`« ${orphelin.name} » tire sur une autre version : choisissez laquelle, et de combien.`)
  // stockMode n'existe que pour l'ecran : le serveur, lui, lit stockManaged et stockSourceId.
  const b = { ...v, values: v.values.filter(x => x.name?.trim()).map((x, i) => { const { stockMode, ...reste } = x; return { ...reste, sortOrder: i } }) }
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
        <div v-for="(x, i) in edit.values" :key="i" class="bloc">
          <div class="ligne">
            <input class="input" v-model="x.name" maxlength="60" placeholder="ex. Large" />
            <input class="input" v-model="x.shortName" maxlength="20" :placeholder="x.name || 'idem'" />
            <label class="check"><input type="checkbox" v-model="x.active" /></label>
            <button class="btn sm danger" :disabled="edit.values.length < 2" @click="edit.values.splice(i, 1)">✕</button>
          </div>
          <!-- Le stock se pose sur la version, pas sur l'article : ce qui s'épuise, c'est
               la pâte, et la même pâte sert quarante sandwichs. -->
          <div class="stock">
            <span class="et">Stock</span>
            <select class="input sm" :value="modeStock(x)" @change="setModeStock(x, $event.target.value)">
              <option value="non">Non suivi</option>
              <option value="propre">Compteur propre</option>
              <option value="lie">Tire sur une autre version</option>
            </select>
            <template v-if="modeStock(x) === 'propre'">
              <span class="et">décrémente de</span>
              <input class="input sm num" v-model="x.stockStep" inputmode="decimal" style="width:78px" />
              <span class="tiny muted">par article vendu</span>
            </template>
            <template v-else-if="modeStock(x) === 'lie'">
              <span class="et">sur</span>
              <select class="input sm" :value="x.stockSourceId || ''" @change="setSource(x, $event.target.value)">
                <option value="">— choisir la version —</option>
                <option v-for="s in sources(x)" :key="s.id || s.name" :value="s.id || ''" :disabled="!s.id">
                  {{ s.name || '(sans nom)' }}{{ s.id ? '' : ' — à enregistrer d\'abord' }}
                </option>
              </select>
              <span class="et">×</span>
              <input class="input sm num" v-model="x.stockStep" inputmode="decimal" style="width:78px" />
              <span v-if="x.stockSourceId" class="tiny muted">une vente retire {{ x.stockStep }} sur « {{ nomSource(x) }} »</span>
              <span v-else class="tiny warn">choisissez la version sur laquelle celle-ci tire</span>
            </template>
          </div>
        </div>
        <p class="tiny muted mt-8">
          Une version retirée ou désactivée est refusée si un article l'a pour valeur par défaut :
          il deviendrait invendable sans que personne ne l'apprenne.
        </p>
        <p class="tiny muted mt-8">
          <b>Le stock.</b> « Normale », « Céréale » et « Chia » portent chacune leur compteur ; « Double Normale »
          n'en porte pas et tire sur « Normale » × 2 — c'est la même pâte au frigo, comptée deux fois.
          Les quantités se saisissent en caisse (bouton <b>Stock</b>), le compteur repart à zéro
          à la clôture journalière, et une vente est refusée quand il ne reste plus assez.
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
/* Une version et son réglage de stock forment un bloc : le filet dit où l'une finit. */
.bloc { border-bottom: 1px solid var(--line); padding-bottom: 8px; margin-bottom: 8px; }
.bloc:last-of-type { border-bottom: 0; }
.stock { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; padding: 6px 0 2px 2px; }
.stock .et { font-size: 12.5px; letter-spacing: .06em; text-transform: uppercase; color: var(--ink-3); }
.stock .input.sm { height: 34px; padding: 4px 8px; font-size: 14px; }
/* Les listes gardent leur largeur : etirees sur toute la ligne, le reglage se lisait
   en quatre etages alors qu'il tient en une phrase. */
.stock select.input.sm { flex: 0 1 auto; width: auto; min-width: 168px; max-width: 230px; }
.stock .warn { color: var(--warn); }
.entetes { margin-bottom: 5px; font-size: 11px; font-weight: 700; letter-spacing: .07em; text-transform: uppercase; color: var(--ink-3); }
.ligne + .ligne { margin-top: 7px; }
.ligne .check { justify-content: center; }
</style>
