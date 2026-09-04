<script setup>
import { computed, onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useCatalogStore } from '../../stores/catalog'
import { useBusy } from '../../composables/useApi'
import { fmt } from '../../utils/money'
import Modal from '../../components/common/Modal.vue'
import Icon from '../../components/common/Icon.vue'
const ui = useUiStore(); const catalog = useCatalogStore(); const { busy, run } = useBusy()
const rows = ref([]); const cats = ref([]); const groups = ref([]); const dests = ref([]); const edit = ref(null); const q = ref(''); const catFilter = ref(''); const tab = ref('general')
async function load() { try { [rows.value, cats.value, groups.value, dests.value] = await Promise.all([api.catalog.products(), api.catalog.categories(), api.catalog.modifiers(), api.admin.destinations()]) } catch (e) { ui.error(e.humanMessage) } }
onMounted(load)
/* Sans filtre, la liste est groupée par catégorie : l'ordre étant propre à
   chaque catégorie, une liste globale triée sur le seul rang les entrelacerait. */
const catRank = computed(() => Object.fromEntries(cats.value.map((c, i) => [c.id, i])))
const filtered = computed(() => rows.value
  .filter(p => (!catFilter.value || p.categoryId === Number(catFilter.value)) && (!q.value || (p.name + ' ' + p.code + ' ' + (p.reference || '')).toLowerCase().includes(q.value.toLowerCase())))
  .sort((a, b) => (catRank.value[a.categoryId] ?? 99) - (catRank.value[b.categoryId] ?? 99)))

/* Réordonner n'a de sens que si la liste affichée est exactement une catégorie
   entière : sur une liste filtrée ou cherchée, on renumérote un sous-ensemble
   et l'ordre réel devient faux sans que personne ne le voie. */
const canReorder = computed(() => !!catFilter.value && !q.value.trim())
const dragId = ref(null)

function move(from, to) {
  if (from === to) return
  const seq = filtered.value.slice()
  const [item] = seq.splice(from, 1)
  seq.splice(to, 0, item)
  // La catégorie occupe certaines places dans rows : on les remplit
  // avec la nouvelle séquence, sans toucher aux autres catégories.
  const catId = Number(catFilter.value)
  const places = rows.value.map((p, i) => p.categoryId === catId ? i : -1).filter(i => i >= 0)
  places.forEach((place, k) => { rows.value[place] = seq[k] })
}
function onDragStart(p) { if (canReorder.value) dragId.value = p.id }
function onDragOver(e, i) {
  if (dragId.value === null) return
  e.preventDefault()
  const from = filtered.value.findIndex(x => x.id === dragId.value)
  if (from >= 0 && from !== i) move(from, i)
}
async function onDrop() {
  if (dragId.value === null) return
  dragId.value = null
  const catId = Number(catFilter.value)
  const ids = rows.value.filter(p => p.categoryId === catId).map(p => p.id)
  if (await run(() => api.catalog.reorderProducts(ids), { success: 'Ordre enregistré' })) {
    load(); catalog.load(true).catch(() => {})
  }
}
const simpleProducts = computed(() => rows.value.filter(p => p.productType === 'SIMPLE'))
function nextCode(catId) { const c = cats.value.find(x => x.id === catId); const pre = (c?.name || 'PRD').slice(0, 3).toUpperCase().replace(/[^A-Z]/g, 'X'); let n = 1; while (rows.value.some(p => p.code === `${pre}-${String(n).padStart(3, '0')}`)) n++; return `${pre}-${String(n).padStart(3, '0')}` }
function create() { const catId = Number(catFilter.value) || cats.value[0]?.id; edit.value = { code: nextCode(catId), reference: '', name: '', shortName: '', description: '', categoryId: catId, productType: 'SIMPLE', price: 0, taxRate: 0, imageUrl: '', color: '', sortOrder: rows.value.length + 1, active: true, available: true, favorite: false, favoriteOrder: 0, printDestinationIds: [], modifierGroupIds: [], menuComponents: [] }; tab.value = 'general' }
function open(p) { edit.value = { ...p, modifierGroupIds: p.modifierGroups.map(g => g.id), menuComponents: p.menuComponents.map(c => ({ name: c.name, quantity: c.quantity, sortOrder: c.sortOrder, options: c.options.map(o => ({ productId: o.productId, priceDelta: Number(o.priceDelta) })) })) }; tab.value = 'general' }
async function save() {
  const b = { ...edit.value, price: Number(String(edit.value.price).replace(',', '.')), taxRate: Number(edit.value.taxRate) || 0, menuComponents: edit.value.productType === 'MENU' ? edit.value.menuComponents.map((c, i) => ({ ...c, sortOrder: i, quantity: Number(c.quantity) || 1, options: c.options.map(o => ({ productId: o.productId, priceDelta: Number(o.priceDelta) || 0 })) })) : [] }
  const r = await run(() => api.catalog.saveProduct(edit.value.id, b), { success: 'Produit enregistré' }); if (r) { edit.value = null; load(); catalog.load(true).catch(() => {}) }
}
async function toggleAvail(p) { const r = await run(() => api.catalog.availability(p.id, !p.available)); if (r) { load(); catalog.load(true).catch(() => {}) } }
async function remove(p) { if (!await ui.confirm({ title: 'Supprimer', message: `Supprimer « ${p.name} » ? (impossible s'il a déjà été vendu — désactivez-le alors)`, okLabel: 'Supprimer', danger: true })) return; if (await run(() => api.catalog.deleteProduct(p.id), { success: 'Supprimé' })) { load(); catalog.load(true).catch(() => {}) } }
function toggleIn(list, id) { const i = list.indexOf(id); if (i >= 0) list.splice(i, 1); else list.push(id) }
function addComponent() { edit.value.menuComponents.push({ name: '', quantity: 1, options: [] }) }
function toggleOption(c, pid) { const i = c.options.findIndex(o => o.productId === pid); if (i >= 0) c.options.splice(i, 1); else c.options.push({ productId: pid, priceDelta: 0 }) }
function onImage(e) { const f = e.target.files[0]; if (!f) return; if (f.size > 400 * 1024) return ui.error('Image trop lourde (max 400 Ko).'); const r = new FileReader(); r.onload = () => { edit.value.imageUrl = r.result }; r.readAsDataURL(f) }
</script>
<template>
  <div class="toolbar"><button class="btn primary" @click="create">+ Nouveau produit / menu</button><input class="input" v-model="q" placeholder="Rechercher…" /><select class="input" v-model="catFilter"><option value="">Toutes catégories</option><option v-for="c in cats" :key="c.id" :value="c.id">{{ c.name }}</option></select><span class="muted small">{{ filtered.length }} produit(s)</span>
    <span class="reorder-hint" :class="canReorder ? 'on' : 'off'">
      <b>Ordre d'affichage</b>
      <template v-if="canReorder">glissez une ligne par sa poignée pour la déplacer</template>
      <template v-else>choisissez une catégorie{{ q.trim() ? ' et videz la recherche' : '' }} pour pouvoir réordonner</template>
    </span></div>
  <div class="table-wrap"><table class="table">
    <thead><tr><th class="ord">Ordre</th><th>Code</th><th>Produit</th><th>Catégorie</th><th class="right">Prix</th><th>Type</th><th>Options</th><th>Impression</th><th>Favori</th><th>Dispo</th><th>Actif</th><th></th></tr></thead>
    <tbody><tr v-for="(p, i) in filtered" :key="p.id" :style="{ opacity: p.active ? 1 : .55 }"
                 :class="{ drag: canReorder, dragging: dragId === p.id }" :draggable="canReorder"
                 @dragstart="onDragStart(p)" @dragover="onDragOver($event, i)" @drop.prevent="onDrop" @dragend="onDrop">
      <td class="ord"><span v-if="canReorder" class="grip" aria-hidden="true"></span><b class="num">{{ i + 1 }}</b></td>
      <td class="small">{{ p.code }}</td><td><b>{{ p.name }}</b><div class="tiny muted" v-if="p.shortName && p.shortName!==p.name">ticket : {{ p.shortName }}</div></td><td><span class="color-dot" :style="{ background: cats.find(c=>c.id===p.categoryId)?.color }"></span>{{ p.categoryName }}</td><td class="right num bold">{{ fmt(p.price) }}</td>
      <td><span class="badge" :class="p.productType==='MENU' ? 'accent' : ''">{{ p.productType==='MENU' ? 'Menu' : 'Simple' }}</span></td><td class="small">{{ p.modifierGroups.map(g=>g.name).join(', ') }}</td>
      <td class="small">{{ p.printDestinationIds.length ? p.printDestinationIds.map(id => dests.find(d=>d.id===id)?.name).join(', ') : '(catégorie)' }}</td><td><Icon v-if="p.favorite" name="star" :size="16" style="color:var(--warn)" /></td>
      <td><button class="btn sm" :class="p.available ? 'success' : 'danger solid'" @click="toggleAvail(p)">{{ p.available ? 'Disponible' : 'INDISPONIBLE' }}</button></td><td><span class="badge" :class="p.active ? 'success' : 'danger'">{{ p.active ? 'Oui' : 'Non' }}</span></td>
      <td class="actions"><button class="btn sm" @click="open(p)">Modifier</button> <button class="btn sm danger" @click="remove(p)">✕</button></td></tr></tbody></table></div>
  <Modal v-if="edit" size="lg" :title="edit.id ? 'Modifier : ' + edit.name : 'Nouveau produit'" @close="edit=null">
    <div class="tabs"><button :class="{ on: tab==='general' }" @click="tab='general'">Général</button><button :class="{ on: tab==='options' }" @click="tab='options'">Options ({{ edit.modifierGroupIds.length }})</button><button v-if="edit.productType==='MENU'" :class="{ on: tab==='menu' }" @click="tab='menu'">Composition du menu</button><button :class="{ on: tab==='print' }" @click="tab='print'">Impression & POS</button></div>
    <div v-show="tab==='general'" class="form-grid">
      <div class="field"><label>Type</label><select class="input" v-model="edit.productType"><option value="SIMPLE">Produit simple</option><option value="MENU">Menu / formule</option></select></div>
      <div class="field"><label>Catégorie</label><select class="input" v-model="edit.categoryId"><option v-for="c in cats" :key="c.id" :value="c.id">{{ c.name }}</option></select></div>
      <div class="field"><label>Nom</label><input class="input" v-model="edit.name" /></div>
      <div class="field"><label>Nom court (ticket)</label><input class="input" v-model="edit.shortName" maxlength="40" /></div>
      <div class="field"><label>Code</label><input class="input" v-model="edit.code" /></div>
      <div class="field"><label>Référence</label><input class="input" v-model="edit.reference" /></div>
      <div class="field"><label>Prix TTC</label><input class="input lg" v-model="edit.price" inputmode="decimal" /></div>
      <div class="field"><label>TVA % (si activée)</label><input class="input" v-model="edit.taxRate" inputmode="decimal" /></div>
      <div class="field span-2"><label>Description</label><input class="input" v-model="edit.description" /></div>
      <div class="field"><label>Image</label><div class="row"><img v-if="edit.imageUrl" :src="edit.imageUrl" style="width:56px;height:56px;object-fit:cover;border-radius:8px" /><input type="file" accept="image/*" @change="onImage" /><button v-if="edit.imageUrl" class="btn sm" @click="edit.imageUrl=''">Retirer</button></div></div>
      <div class="field"><label>Couleur de la tuile (vide = couleur catégorie)</label><input class="input" v-model="edit.color" placeholder="#f97316" /></div>
      <label class="check"><input type="checkbox" v-model="edit.active" /> Actif (au catalogue)</label>
      <label class="check"><input type="checkbox" v-model="edit.available" /> Disponible à la vente</label>
    </div>
    <div v-show="tab==='options'" class="col gap-8">
      <p class="muted small">Cochez les groupes d'options proposés au caissier lors de l'ajout de ce produit. L'ordre suit l'ordre de sélection.</p>
      <label v-for="g in groups" :key="g.id" class="check card tight"><input type="checkbox" :checked="edit.modifierGroupIds.includes(g.id)" @change="toggleIn(edit.modifierGroupIds, g.id)" /><div><b>{{ g.name }}</b> <span class="badge" v-if="g.required">obligatoire</span><div class="tiny muted">{{ g.modifiers.map(m => m.name + (Number(m.priceDelta) ? ' +' + fmt(m.priceDelta) : '')).join(', ') }}</div></div></label>
      <p v-if="!groups.length" class="muted">Aucun groupe d'options — créez-en dans « Options & suppléments ».</p>
    </div>
    <div v-show="tab==='menu'" class="col gap-8">
      <p class="muted small">Chaque composant demande un nombre de choix parmi des produits. Un supplément peut s'appliquer par option (ex. +2,000 pour un Double Cheese).</p>
      <div v-for="(c, i) in edit.menuComponents" :key="i" class="card tight">
        <div class="row gap-8 mb-8"><input class="input grow" v-model="c.name" placeholder="Nom du composant (ex. Burger)" /><input class="input" type="number" min="1" v-model.number="c.quantity" style="width:90px" title="Quantité à choisir" /><button class="btn sm icon danger" @click="edit.menuComponents.splice(i,1)">✕</button></div>
        <div class="row wrap gap-6">
          <div v-for="p in simpleProducts" :key="p.id" class="row gap-4" style="border:1px solid var(--border);border-radius:10px;padding:4px 8px" :style="{ background: c.options.some(o=>o.productId===p.id) ? 'var(--success-soft)' : '' }">
            <label class="check small" style="min-height:32px"><input type="checkbox" :checked="c.options.some(o=>o.productId===p.id)" @change="toggleOption(c, p.id)" />{{ p.name }}</label>
            <input v-if="c.options.some(o=>o.productId===p.id)" class="input" style="width:80px;min-height:32px;padding:4px 8px" v-model="c.options.find(o=>o.productId===p.id).priceDelta" inputmode="decimal" title="Supplément" />
          </div>
        </div>
      </div>
      <button class="btn soft" @click="addComponent">+ Ajouter un composant</button>
    </div>
    <div v-show="tab==='print'" class="form-grid">
      <div class="field span-2"><label>Destinations d'impression (vide = destination de la catégorie)</label><div class="row wrap gap-6"><label v-for="d in dests.filter(d => d.kind==='PREP')" :key="d.id" class="check"><input type="checkbox" :checked="edit.printDestinationIds.includes(d.id)" @change="toggleIn(edit.printDestinationIds, d.id)" />{{ d.name }}</label></div></div>
      <label class="check"><input type="checkbox" v-model="edit.favorite" /> Favori (catégorie Favoris du POS)</label>
      <div class="field"><label>Ordre dans les favoris</label><input class="input" type="number" v-model.number="edit.favoriteOrder" /></div>
      <div class="field"><label>Ordre d'affichage</label><input class="input" type="number" v-model.number="edit.sortOrder" /></div>
    </div>
    <template #foot><button class="btn lg" @click="edit=null">Annuler</button><button class="btn lg primary" :disabled="busy || !edit.name || !edit.code" @click="save">Enregistrer</button></template>
  </Modal>
</template>

<style scoped>
/* L'indication vit a cote du selecteur de categorie, pas reléguée au bout de la barre :
   c'est ce selecteur qui commande le glisser-deposer, et une mention pale a l'autre bout
   de l'ecran passait inapercue — on croyait la fonction absente. */
.reorder-hint {
  display: inline-flex; align-items: baseline; gap: 7px; padding: 5px 11px;
  border-radius: 999px; font-size: 12px; line-height: 1.3;
}
.reorder-hint b { font-size: 11px; font-weight: 750; letter-spacing: .05em; text-transform: uppercase; }
.reorder-hint.on { background: var(--brand-soft); color: var(--ink-2); border: 1px solid var(--brand-line); }
.reorder-hint.on b { color: var(--brand); }
.reorder-hint.off { background: var(--surface-2); color: var(--ink-3); border: 1px dashed var(--line-2); }

.ord { width: 74px; white-space: nowrap; }
.ord b { font-size: 13px; font-weight: 700; color: var(--ink-2); }

/* Poignée : trois points doublés, dessinés en dégradés pour éviter
   une icône de plus dans le jeu partagé. */
.grip {
  display: inline-block; width: 9px; height: 14px; margin-right: 8px; vertical-align: -2px;
  background-image: radial-gradient(circle, var(--ink-4) 1.1px, transparent 1.2px);
  background-size: 4.5px 4.5px; opacity: .85;
}
tr.drag { cursor: grab; }
tr.drag:hover { background: var(--surface-2); }
tr.drag:hover .grip { opacity: 1; }
tr.dragging { opacity: .45; cursor: grabbing; background: var(--brand-soft); }
</style>
