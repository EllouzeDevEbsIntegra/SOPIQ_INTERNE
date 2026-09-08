<script setup>
import { computed, onMounted, ref, watch } from 'vue'
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
onMounted(() => { load(); chargerIngredients(); chargerVariantes() })
/* Sans filtre, la liste est groupée par catégorie : l'ordre étant propre à
   chaque catégorie, une liste globale triée sur le seul rang les entrelacerait. */
const catRank = computed(() => Object.fromEntries(cats.value.map((c, i) => [c.id, i])))
/* Deux filtres qui ne servent qu'une fois, mais ce jour-la ils font tout : apres l'import
   d'une carte entiere, retrouver les prix qui restent a confirmer et les articles qu'on a
   oublie de decliner - sans ouvrir les fiches une par une. */
const aVerifier = ref(false)
const sansVariante = ref(false)
const filtered = computed(() => rows.value
  .filter(p => (!catFilter.value || p.categoryId === Number(catFilter.value)) && (!q.value || (p.name + ' ' + p.code + ' ' + (p.reference || '')).toLowerCase().includes(q.value.toLowerCase())))
  .filter(p => !aVerifier.value || p.priceToCheck)
  .filter(p => !sansVariante.value || !p.variantId)
  .sort((a, b) => (catRank.value[a.categoryId] ?? 99) - (catRank.value[b.categoryId] ?? 99)))

/* Réordonner n'a de sens que si la liste affichée est exactement une catégorie
   entière : sur une liste filtrée ou cherchée, on renumérote un sous-ensemble
   et l'ordre réel devient faux sans que personne ne le voie. */
const nbAVerifier = computed(() => rows.value.filter(p => p.priceToCheck).length)
const canReorder = computed(() => !!catFilter.value && !q.value.trim() && !aVerifier.value && !sansVariante.value)
const dragId = ref(null)

/*
    Composition du nom par ingredients.

    Toucher « Omelette », « Thon », « Salami » ecrit « Omelette Thon Salami ». C'est une
    aide a la saisie : le champ reste librement modifiable ensuite, et rien n'oblige a
    passer par la.

    Les ingredients retenus sont aussi ENREGISTRES avec l'article, separement du nom. Le
    nom est une chaine de caracteres, qu'on ne peut pas relire a coup sur - « Thon »
    apparait dans « Thonine ». Le lien, lui, permettra de retrouver en caisse les articles
    qui contiennent tel et tel ingredient.
*/
const ingredients = ref([])

/*
    Variantes : au plus une par article.

    Le prix se tient ici, par version, et non sur la variante : la meme « Large » ne vaut
    pas le meme prix sur une pizza thon et sur une pizza fruits de mer. Un prix a zero
    signifie « pas encore tarifee » — la version apparait alors grisee en caisse, ce qui
    dit au gerant ce qui lui reste a faire, plutot que de la faire disparaitre sans un mot.
*/
const variantes = ref([])
async function chargerVariantes() { try { variantes.value = await api.admin.variants() } catch { /* liste facultative */ } }
function nomValeur(variantId, valueId) {
  const v = variantes.value.find(x => x.id === variantId)
  return v?.values?.find(x => x.id === valueId)?.name || 'sans defaut'
}
const axeChoisi = computed(() => variantes.value.find(v => v.id === edit.value?.variantId) || null)
const versionsAxe = computed(() => (axeChoisi.value?.values || []).filter(v => v.active))

function prixVersion(id) {
  return (edit.value.variantPrices || []).find(p => p.variantValueId === id)?.price ?? ''
}
function setPrixVersion(id, v) {
  const liste = edit.value.variantPrices || (edit.value.variantPrices = [])
  const ligne = liste.find(p => p.variantValueId === id)
  const n = Number(String(v).replace(',', '.')) || 0
  if (ligne) ligne.price = n; else liste.push({ variantValueId: id, price: n })
}
/* Changer d'axe rend la grille de prix precedente absurde : on repart a zero plutot que
   de garder des prix qui se rattachaient a des versions disparues. */
function changerAxe(id) {
  edit.value.variantId = id || null
  edit.value.variantPrices = []
  edit.value.defaultVariantValueId = null
  if (!id) edit.value.askVariant = false
}

/* Meme palette que les categories : deux jeux de couleurs differents dans un meme
   back-office donneraient deux cartes qui ne se ressemblent pas. */
const COULEURS = ['#f97316', '#eab308', '#ef4444', '#8b5cf6', '#0ea5e9', '#ec4899', '#22c55e', '#10b981', '#3b82f6', '#64748b', '#a16207', '#0f172a']
/* Couleur reellement appliquee quand le champ reste vide : la montrer vaut mieux que de
   l'ecrire entre parentheses dans un libelle que personne ne lit. */
const couleurCategorie = computed(() => cats.value.find(c => c.id === edit.value?.categoryId)?.color || '#8A8178')

/*
    Changer un article de rubrique lui donne la couleur de sa nouvelle rubrique.

    La couleur d'une tuile est vide par defaut : la tuile prend alors celle de sa
    rubrique, et suit donc toute seule. Mais un article peut porter EN DUR la couleur de
    l'ancienne rubrique - c'est le cas de tous ceux qu'un import a colories - et il
    debarquerait en rouge au milieu des verts sans que rien ne le signale.

    On ne remet a l'heritage que dans ce cas precis : couleur vide, ou identique a celle
    de la rubrique qu'on quitte. Une couleur choisie exprimee pour cet article-la, elle,
    est respectee - c'est un choix, pas un reste.
*/
watch(() => edit.value?.categoryId, (vers, avant) => {
  if (!edit.value || vers == null || avant == null || vers === avant) return
  const ancienne = cats.value.find(c => c.id === avant)?.color
  if (!edit.value.color || edit.value.color === ancienne) edit.value.color = ''
})
async function chargerIngredients() { try { ingredients.value = await api.admin.ingredients() } catch { /* liste facultative */ } }

function nomCompose(ids) {
  return ids.map(id => ingredients.value.find(i => i.id === id)?.name).filter(Boolean).join(' ')
}
/* Le nom du ticket suit les memes touches, en abrege : « Omlette Mozarilla Thon » d'un
   cote, « Oml Moz Thon » de l'autre. Un ingredient sans abreviation donne son nom entier
   plutot que rien - un ticket long vaut mieux qu'un ticket muet. */
function ticketCompose(ids) {
  return ids.map(id => { const i = ingredients.value.find(x => x.id === id); return i && (i.shortName || i.name) })
            .filter(Boolean).join(' ')
}
/* On ne reecrit le nom que s'il decoule encore des ingredients : des qu'il a ete retouche
   a la main, une touche d'ingredient ne doit pas effacer ce que l'utilisateur a ecrit.
   Le nom du ticket suit la meme regle, jugee sur SA propre composition. */
function basculerIngredient(id) {
  const liste = edit.value.ingredientIds || (edit.value.ingredientIds = [])
  const i = liste.indexOf(id)
  const suivait = edit.value.name === nomCompose(liste)
  const suivaitTicket = !edit.value.shortName?.trim() || edit.value.shortName === ticketCompose(liste)
  if (i >= 0) liste.splice(i, 1); else liste.push(id)
  if (suivait || !edit.value.name?.trim()) edit.value.name = nomCompose(liste)
  if (suivaitTicket) edit.value.shortName = ticketCompose(liste)
}

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
function create() { const catId = Number(catFilter.value) || cats.value[0]?.id; edit.value = { code: nextCode(catId), reference: '', name: '', shortName: '', description: '', categoryId: catId, productType: 'SIMPLE', price: 0, taxRate: 0, imageUrl: '', color: '', sortOrder: rows.value.length + 1, active: true, available: true, favorite: false, favoriteOrder: 0, priceToCheck: false, printDestinationIds: [], modifierGroupIds: [], menuComponents: [], ingredientIds: [], variantId: null, defaultVariantValueId: null, askVariant: false, variantPrices: [] }; tab.value = 'general' }
function open(p) { edit.value = { ...p, ingredientIds: [...(p.ingredientIds || [])], variantPrices: (p.variantPrices || []).map(x => ({ ...x })), modifierGroupIds: p.modifierGroups.map(g => g.id), menuComponents: p.menuComponents.map(c => ({ name: c.name, quantity: c.quantity, sortOrder: c.sortOrder, options: c.options.map(o => ({ productId: o.productId, priceDelta: Number(o.priceDelta) })) })) }; tab.value = 'general' }
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
    <button class="btn sm" :class="{ 'warn solid': aVerifier }" @click="aVerifier = !aVerifier">
      Prix à vérifier<span class="pastille num" v-if="nbAVerifier">{{ nbAVerifier }}</span>
    </button>
    <button class="btn sm" :class="{ 'warn solid': sansVariante }" @click="sansVariante = !sansVariante">Sans variante</button>
    <span class="reorder-hint" :class="canReorder ? 'on' : 'off'">
      <b>Ordre d'affichage</b>
      <template v-if="canReorder">glissez une ligne par sa poignée pour la déplacer</template>
      <template v-else>choisissez une catégorie{{ q.trim() ? ' et videz la recherche' : '' }} pour pouvoir réordonner</template>
    </span></div>
  <div class="table-wrap"><table class="table">
    <thead><tr><th class="ord">Ordre</th><th>Code</th><th>Produit</th><th>Catégorie</th><th class="right">Prix</th><th>Variante</th><th>Type</th><th>Options</th><th>Impression</th><th>Favori</th><th>Dispo</th><th>Actif</th><th></th></tr></thead>
    <tbody><tr v-for="(p, i) in filtered" :key="p.id" :style="{ opacity: p.active ? 1 : .55 }"
                 :class="{ drag: canReorder, dragging: dragId === p.id }" :draggable="canReorder"
                 @dragstart="onDragStart(p)" @dragover="onDragOver($event, i)" @drop.prevent="onDrop" @dragend="onDrop">
      <td class="ord"><span v-if="canReorder" class="grip" aria-hidden="true"></span><b class="num">{{ i + 1 }}</b></td>
      <td class="small">{{ p.code }}</td><td><b>{{ p.name }}</b><div class="tiny muted" v-if="p.shortName && p.shortName!==p.name">ticket : {{ p.shortName }}</div></td><td><span class="color-dot" :style="{ background: cats.find(c=>c.id===p.categoryId)?.color }"></span>{{ p.categoryName }}</td><td class="right num bold">{{ fmt(p.price) }}<span v-if="p.priceToCheck" class="flag" title="Prix a verifier : il ne vient pas de la carte">a verifier</span></td>
      <!-- Colonne des variantes : d'un coup d'oeil, qui est decline et qui ne l'est pas.
           Sans elle, il faudrait ouvrir 97 fiches pour trouver celle qu'on a oubliee. -->
      <td class="small">
        <template v-if="p.variantId">
          <b>{{ variantes.find(v => v.id === p.variantId)?.name }}</b>
          <div class="tiny muted">{{ nomValeur(p.variantId, p.defaultVariantValueId) }}<span v-if="p.askVariant"> · demande</span></div>
        </template>
        <span v-else class="muted">&mdash;</span>
      </td>
      <td><span class="badge" :class="p.productType==='MENU' ? 'accent' : ''">{{ p.productType==='MENU' ? 'Menu' : 'Simple' }}</span></td><td class="small">{{ p.modifierGroups.map(g=>g.name).join(', ') }}</td>
      <td class="small">{{ p.printDestinationIds.length ? p.printDestinationIds.map(id => dests.find(d=>d.id===id)?.name).join(', ') : '(catégorie)' }}</td><td><Icon v-if="p.favorite" name="star" :size="16" style="color:var(--warn)" /></td>
      <td><button class="btn sm" :class="p.available ? 'success' : 'danger solid'" @click="toggleAvail(p)">{{ p.available ? 'Disponible' : 'INDISPONIBLE' }}</button></td><td><span class="badge" :class="p.active ? 'success' : 'danger'">{{ p.active ? 'Oui' : 'Non' }}</span></td>
      <td class="actions"><button class="btn sm" @click="open(p)">Modifier</button> <button class="btn sm danger" @click="remove(p)">✕</button></td></tr></tbody></table></div>
  <Modal v-if="edit" size="lg" :title="edit.id ? 'Modifier : ' + edit.name : 'Nouveau produit'" @close="edit=null">
    <div class="tabs"><button :class="{ on: tab==='general' }" @click="tab='general'">Général</button><button :class="{ on: tab==='options' }" @click="tab='options'">Options ({{ edit.modifierGroupIds.length }})</button><button v-if="edit.productType==='MENU'" :class="{ on: tab==='menu' }" @click="tab='menu'">Composition du menu</button><button :class="{ on: tab==='print' }" @click="tab='print'">Impression & POS</button></div>
    <div v-show="tab==='general'" class="form-grid">
      <div class="field"><label>Type</label><select class="input" v-model="edit.productType"><option value="SIMPLE">Produit simple</option><option value="MENU">Menu / formule</option></select></div>
      <div class="field"><label>Catégorie</label><select class="input" v-model="edit.categoryId"><option v-for="c in cats" :key="c.id" :value="c.id">{{ c.name }}</option></select></div>
      <div class="field span-2">
        <label>Nom</label>
        <input class="input" v-model="edit.name" />
        <!-- Touches de composition : le nom s'ecrit dans l'ordre des appuis. Les
             ingredients retenus sont enregistres avec l'article, ce qui permettra de le
             retrouver par eux en caisse - un nom seul ne s'analyse pas de facon sure. -->
        <div class="ingr" v-if="ingredients.length">
          <button v-for="ing in ingredients.filter(i => i.active)" :key="ing.id" type="button"
                  class="chip-ingr" :class="{ on: (edit.ingredientIds || []).includes(ing.id) }"
                  @click="basculerIngredient(ing.id)">
            <span v-if="(edit.ingredientIds || []).includes(ing.id)" class="rang num">{{ (edit.ingredientIds || []).indexOf(ing.id) + 1 }}</span>
            {{ ing.name }}
          </button>
          <span class="ingr-aide">Touchez dans l'ordre voulu — le nom reste modifiable à la main.</span>
        </div>
      </div>
      <!-- Laisse vide, le ticket imprime deja le nom complet : l'invite le montre, pour
           qu'on n'ait plus a le deviner. Le bouton recopie le nom quand on veut partir de
           lui pour l'abreger - « Sandwich Escalope Complet » en « Sandw. Escalope ». -->
      <div class="field">
        <label>Nom court (ticket)</label>
        <div class="row gap-6">
          <input class="input grow" v-model="edit.shortName" maxlength="40"
                 :placeholder="edit.name ? edit.name + '  (nom complet)' : 'vide = le nom ci-dessus'" />
          <button class="btn icon" type="button" :disabled="!edit.name"
                  :title="'Reprendre le nom : ' + (edit.name || '')"
                  @click="edit.shortName = (edit.name || '').slice(0, 40)">
            <Icon name="copy" :size="17" />
          </button>
        </div>
      </div>
      <div class="field"><label>Code</label><input class="input" v-model="edit.code" /></div>
      <div class="field"><label>Référence</label><input class="input" v-model="edit.reference" /></div>
      <div class="field">
        <label>Prix TTC</label>
        <input class="input lg" v-model="edit.price" inputmode="decimal" />
        <!-- La case s'eteint quand le gerant a confirme le tarif : c'est elle qui vide
             peu a peu la colonne « a verifier » de la liste. -->
        <label class="check mt-6"><input type="checkbox" v-model="edit.priceToCheck" /> Prix à vérifier</label>
      </div>
      <div class="field"><label>TVA % (si activée)</label><input class="input" v-model="edit.taxRate" inputmode="decimal" /></div>
      <div class="field span-2"><label>Description</label><input class="input" v-model="edit.description" /></div>
      <!--
          Variante : les versions du meme plat, chacune a son prix.

          Le prix affiche plus haut ne sert plus des qu'un axe est choisi : c'est la grille
          qui fait foi. Le prix est COMPLET et non un supplement - « Large = 18 DT » -, ce
          qui evite toute hypothese sur la decomposabilite des tarifs.
      -->
      <div class="variante span-2">
        <div class="row wrap gap-12 items-end">
          <div class="field" style="min-width:230px">
            <label>Versions de cet article</label>
            <select class="input" :value="edit.variantId || ''" @change="changerAxe(Number($event.target.value) || null)">
              <option value="">Aucune — prix unique</option>
              <option v-for="v in variantes.filter(x => x.active)" :key="v.id" :value="v.id">{{ v.name }}</option>
            </select>
          </div>
          <label v-if="axeChoisi" class="check demander">
            <input type="checkbox" v-model="edit.askVariant" />
            <span><b>Toujours demander</b><em>Sinon, un appui court vend la version par défaut</em></span>
          </label>
        </div>

        <div v-if="axeChoisi" class="grille">
          <div class="entetes"><span>Version</span><span>Prix</span><span>Par défaut</span></div>
          <label v-for="v in versionsAxe" :key="v.id" class="ligne" :class="{ def: edit.defaultVariantValueId === v.id }">
            <span class="nom">{{ v.name }}<em v-if="v.shortName"> · ticket : {{ v.shortName }}</em></span>
            <input class="input" inputmode="decimal" :value="prixVersion(v.id)" placeholder="0,000"
                   @input="setPrixVersion(v.id, $event.target.value)" />
            <span class="radio">
              <input type="radio" name="versionDefaut" :checked="edit.defaultVariantValueId === v.id"
                     @change="edit.defaultVariantValueId = v.id" />
            </span>
          </label>
          <p class="tiny muted mt-8">
            La version par défaut est obligatoire et doit avoir un prix : c'est elle que vend un appui court.
            Une version laissée à 0 apparaît grisée en caisse — elle n'est pas vendable tant qu'elle n'est pas tarifée.
          </p>
        </div>
      </div>

      <!--
          Apparence et etat de l'article.

          Ces trois reglages n'ont rien a voir entre eux et se disputaient une meme rangee
          de la grille. Ils forment desormais une bande a part, chacun avec la cible que
          reclame un doigt :

          - le selecteur de fichier natif, dont Windows n'ecrit meme pas le texte en
            francais, disparait derriere la vignette elle-meme ;
          - la couleur se choisissait au clavier, en hexadecimal : impossible sur un poste
            tactile. Les pastilles la rendent touchable, et « Categorie » remplace le
            « vide = couleur categorie » du libelle par un choix qu'on voit ;
          - « Actif » et « Disponible » se ressemblaient trop pour qu'on sache lequel
            retirer un plat de la carte et lequel dit qu'il est en rupture ce midi.
      -->
      <div class="apparence span-2">
        <section class="bloc">
          <span class="titre">Image</span>
          <div class="row gap-10">
            <label class="vignette" :class="{ vide: !edit.imageUrl }" title="Choisir une photo">
              <img v-if="edit.imageUrl" :src="edit.imageUrl" alt="" />
              <template v-else><Icon name="image" :size="24" /><span>Ajouter</span></template>
              <input type="file" accept="image/*" hidden @change="onImage" />
            </label>
            <div class="col gap-6" v-if="edit.imageUrl">
              <label class="btn sm">Remplacer<input type="file" accept="image/*" hidden @change="onImage" /></label>
              <button type="button" class="btn sm danger" @click="edit.imageUrl = ''">Retirer</button>
            </div>
          </div>
        </section>

        <section class="bloc grow">
          <span class="titre">Couleur de la tuile</span>
          <div class="pastilles">
            <button type="button" class="herite" :class="{ on: !edit.color }"
                    title="Reprendre la couleur de la catégorie" @click="edit.color = ''">
              <i :style="{ background: couleurCategorie }"></i>Catégorie
            </button>
            <button v-for="c in COULEURS" :key="c" type="button" class="sw" :class="{ on: edit.color === c }"
                    :style="{ background: c }" :title="c" @click="edit.color = c"></button>
            <input class="input hex" v-model="edit.color" placeholder="#C8441C" maxlength="7" title="Couleur précise" />
          </div>
        </section>

        <section class="bloc">
          <span class="titre">État</span>
          <div class="etats">
            <label class="etat" :class="{ on: edit.active }">
              <input type="checkbox" v-model="edit.active" />
              <span><b>Actif</b><em>Figure au catalogue</em></span>
            </label>
            <label class="etat" :class="{ on: edit.available }">
              <input type="checkbox" v-model="edit.available" />
              <span><b>Disponible</b><em>Vendable aujourd'hui</em></span>
            </label>
          </div>
        </section>
      </div>
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
.pastille {
  display: inline-block; margin-left: 6px; padding: 0 6px; border-radius: 999px;
  font-size: 11px; font-weight: 700; background: var(--warn); color: #fff;
}
.btn.warn.solid .pastille { background: rgba(255,255,255,.28); }
/* Le drapeau se lit dans la colonne du prix, la ou le doute porte. Il n'empeche rien :
   l'article se vend, mais on sait qu'il reste a confirmer. */
.flag {
  display: inline-block; margin-left: 8px; padding: 1px 7px; border-radius: 999px;
  font-size: 11px; font-weight: 600; letter-spacing: .02em; white-space: nowrap;
  color: var(--warn); border: 1px solid var(--warn); background: transparent;
}
/* --- variante --- */
.variante { padding: 16px 0 4px; margin-top: 4px; border-top: 1px solid var(--line); }
.variante .demander { align-items: flex-start; gap: 9px; padding: 8px 13px; border: 1px solid var(--line-2); border-radius: var(--r-lg); }
.variante .demander span { display: flex; flex-direction: column; line-height: 1.25; }
.variante .demander b { font-size: 13.5px; font-weight: 650; }
.variante .demander em { font-style: normal; font-size: 11.5px; color: var(--ink-3); }

.grille { margin-top: 14px; max-width: 520px; }
.grille .entetes, .grille .ligne { display: grid; grid-template-columns: 1fr 130px 84px; gap: 10px; align-items: center; }
.grille .entetes { margin-bottom: 6px; font-size: 11px; font-weight: 700; letter-spacing: .07em; text-transform: uppercase; color: var(--ink-3); }
.grille .ligne { min-height: 48px; padding: 0 11px; border: 1px solid var(--line); border-radius: var(--r); cursor: pointer; }
.grille .ligne + .ligne { margin-top: 6px; }
/* La ligne par defaut se distingue : c'est elle que vend un appui court. */
.grille .ligne.def { border-color: var(--brand-line); background: var(--brand-soft); }
.grille .nom { font-size: 14px; font-weight: 600; }
.grille .nom em { font-style: normal; font-size: 11.5px; font-weight: 500; color: var(--ink-3); }
.grille .ligne .input { min-height: 36px; text-align: right; }
.grille .radio { display: flex; justify-content: center; }
.grille .radio input { width: 20px; height: 20px; accent-color: var(--brand); }

/* --- apparence et etat --- */
.apparence {
  display: flex; flex-wrap: wrap; gap: 22px 28px; align-items: flex-start;
  padding: 16px 0 4px; margin-top: 4px; border-top: 1px solid var(--line);
}
.apparence .bloc { display: flex; flex-direction: column; gap: 9px; min-width: 0; }
.apparence .bloc.grow { flex: 1; min-width: 260px; }
.apparence .titre {
  font-size: 11.5px; font-weight: 700; letter-spacing: .07em; text-transform: uppercase; color: var(--ink-3);
}

/* La vignette EST le bouton : plus de selecteur de fichier natif a l'ecran. */
.vignette {
  width: 88px; height: 88px; flex: none; border-radius: var(--r-lg); overflow: hidden;
  display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 3px;
  background: var(--surface-2); border: 1px solid var(--line-2); cursor: pointer;
  color: var(--ink-3); font-size: 11.5px; font-weight: 600;
}
.vignette img { width: 100%; height: 100%; object-fit: cover; }
.vignette.vide { border-style: dashed; }
.vignette:hover { border-color: var(--brand); color: var(--brand); }

.pastilles { display: flex; flex-wrap: wrap; gap: 7px; align-items: center; }
.sw { width: 34px; height: 34px; border-radius: 10px; border: 3px solid transparent; }
.sw.on { border-color: var(--ink); }
/* « Categorie » est une pastille comme les autres : le defaut devient un choix visible. */
.herite {
  display: inline-flex; align-items: center; gap: 7px; height: 34px; padding: 0 12px;
  border: 1px solid var(--line-2); border-radius: 999px; background: var(--surface);
  font-size: 12.5px; font-weight: 600; color: var(--ink-2);
}
.herite i { width: 15px; height: 15px; border-radius: 50%; border: 1px solid rgba(0,0,0,.12); }
.herite.on { border-color: var(--ink); background: var(--surface-2); color: var(--ink); }
.hex { width: 104px; min-height: 34px; padding: 4px 9px; font-size: 12.5px; text-align: center; }

/* Deux etats voisins mais distincts : chacun sa carte, chacun sa phrase. */
.etats { display: flex; gap: 8px; }
.etat {
  display: flex; align-items: center; gap: 9px; min-height: 56px; padding: 8px 13px 8px 11px;
  border: 1px solid var(--line-2); border-radius: var(--r-lg); background: var(--surface); cursor: pointer;
}
.etat input { width: 19px; height: 19px; accent-color: var(--brand); flex: none; }
.etat span { display: flex; flex-direction: column; line-height: 1.25; }
.etat b { font-size: 13.5px; font-weight: 650; }
.etat em { font-style: normal; font-size: 11.5px; color: var(--ink-3); }
.etat.on { border-color: var(--brand-line); background: var(--brand-soft); }

/* --- composition du nom par ingredients --- */
.ingr { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; margin-top: 8px; }
.chip-ingr {
  display: inline-flex; align-items: center; gap: 6px; min-height: 34px; padding: 0 12px;
  border: 1px solid var(--line-2); border-radius: 999px; background: var(--surface);
  font-size: 13px; font-weight: 600; color: var(--ink-2);
}
.chip-ingr:hover { border-color: var(--brand); color: var(--ink); }
/* La pastille porte le RANG, pas une simple coche : c'est l'ordre qui fait le nom. */
.chip-ingr.on { background: var(--brand-soft); border-color: var(--brand); color: var(--ink); }
.chip-ingr .rang {
  display: inline-flex; align-items: center; justify-content: center; width: 17px; height: 17px;
  border-radius: 50%; background: var(--brand); color: #fff; font-size: 10.5px; font-weight: 700;
}
.ingr-aide { font-size: 11.5px; color: var(--ink-4); margin-left: 4px; }

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
