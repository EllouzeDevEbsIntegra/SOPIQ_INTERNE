<script setup>
/*
    L'assistant de commande : traduire ce que le client DIT en lignes de panier.

    Le client annonce « 4 mlewi, 2 pâte céréale omlette thon moz 3arbi dont un sans
    harissa, l'autre sans mayonnaise et frites à part, 1 Number One + avec gruyère sans
    salade… ». Le caissier doit tenir tout cela en tête pendant qu'il cherche des
    articles dont les noms se ressemblent à un mot près. C'est là que se font les
    erreurs, et c'est ce qui part en cuisine.

    TROIS PARTIS PRIS
    1. On cherche par les mots du client, pas par les rubriques : les 76 sandwichs de la
       carte portent leurs ingrédients, et trois pastilles ne laissent qu'un article.
    2. Un seul écran. À gauche on cherche, à droite la commande se remplit — le client
       parle encore, le caissier ne doit jamais perdre le fil.
    3. Le total annoncé sert de contrôle. Sur six sandwichs, celui qu'on oublie ne se
       voit pas ; un compteur qui ne tombe pas juste, si.

    Rien n'est deviné, rien n'est envoyé au serveur : à la fin, les lots deviennent des
    lignes de panier ordinaires, et l'encaissement suit son cours habituel.
*/
import { computed, reactive, ref } from 'vue'
import { useCatalogStore } from '../../stores/catalog'
import { fmt } from '../../utils/money'
import Modal from '../common/Modal.vue'
import Icon from '../common/Icon.vue'

const emit = defineEmits(['close', 'confirm', 'compose'])
const catalog = useCatalogStore()

const sansAccent = (s) => String(s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()

/* ------------------------------------------------------------------ la carte */

const ingredients = computed(() => catalog.ingredients.filter(i => i.active !== false))
const notes = computed(() => catalog.kitchenNotes.filter(n => n.active !== false))

/** Les versions tarifées d'un article, dans l'ordre de l'axe : « Pâte Normale », « Double Pâte Chia »… */
function versions(p) {
  const axe = catalog.variants.find(v => v.id === p.variantId)
  if (!axe) return []
  const prix = Object.fromEntries((p.variantPrices || []).map(x => [x.variantValueId, Number(x.price)]))
  return (axe.values || []).filter(v => v.active !== false && prix[v.id] > 0)
    .map(v => ({ id: v.id, name: v.name, price: prix[v.id] }))
}

/*
    Un article à composer — menu, ou groupe d'options obligatoire — ne se règle pas ici :
    l'assistant produirait une ligne que le serveur refuserait à l'encaissement. On le
    laisse dans les résultats et on passe la main à la fiche habituelle.
*/
const aComposer = (p) => (p.menuComponents || []).length > 0
                      || (p.modifierGroups || []).some(g => g.required)

/* ------------------------------------------------------------------ l'état */

const filtres = ref(new Set())
const rubrique = ref(null)
const texte = ref('')
const annonce = ref(null)
const lots = ref([])
let seq = 0

const courant = ref(null)      // l'article dont la fenêtre est ouverte
const ouvertLot = ref(null)    // la version dépliée ; false = tout replié
const choisi = reactive({})    // versionId -> uid du lot sur lequel les pastilles agissent
const attente = ref(null)      // ce qu'on vient de toucher, en attente du « pour combien ? »

const lotsDe = (p) => lots.value.filter(l => l.product.id === p.id)
const parVersion = (p, vid) => lots.value.filter(l => l.product.id === p.id && (l.version?.id || 0) === vid)
const marques = (l) => l.mods.length + l.notes.length
const prixUnite = (l) => Number(l.version ? l.version.price : l.product.price)
                       + l.mods.reduce((s, m) => s + Number(m.priceDelta), 0)
const totalCommande = computed(() => lots.value.reduce((s, l) => s + prixUnite(l) * l.qte, 0))

/*
    Le compte porte sur les sandwichs, comme le client les annonce. Un sandwich, ici,
    c'est un article qui se décline en pâtes : à la carte, cela recouvre exactement les
    cinq familles de mlewi, et laisse dehors les boissons, les extras et le lablebi.
*/
const estSandwich = (p) => !!p.variantId
const compteSandwichs = computed(() => lots.value.filter(l => estSandwich(l.product)).reduce((s, l) => s + l.qte, 0))
const compteJuste = computed(() => annonce.value == null || compteSandwichs.value === annonce.value)

/* ------------------------------------------------------------------ trouver */

function correspond(p, fs, rub, t) {
  if (!p.active || !p.available) return false
  if (rub && p.categoryId !== rub) return false
  for (const id of fs) if (!(p.ingredientIds || []).includes(id)) return false
  if (t && !sansAccent(p.name + ' ' + (p.shortName || '') + ' ' + (p.code || '')).includes(t)) return false
  return true
}

const resultats = computed(() => {
  const t = sansAccent(texte.value.trim())
  const aucunCritere = !filtres.value.size && !rubrique.value && !t
  if (aucunCritere) return catalog.favorites.length ? catalog.favorites : catalog.products.filter(p => p.active && p.available).slice(0, 24)
  return catalog.products.filter(p => correspond(p, filtres.value, rubrique.value, t))
})
const surFavoris = computed(() => !filtres.value.size && !rubrique.value && !texte.value.trim() && catalog.favorites.length > 0)

/** Ce qu'il resterait si on ajoutait cette pastille : un zéro dit de ne pas la toucher. */
function restant(ingId) {
  const t = sansAccent(texte.value.trim())
  const fs = new Set([...filtres.value, ingId])
  return catalog.products.filter(p => correspond(p, fs, rubrique.value, t)).length
}

function basculerIngredient(id) {
  filtres.value.has(id) ? filtres.value.delete(id) : filtres.value.add(id)
  filtres.value = new Set(filtres.value)
}
function toutEffacer() { filtres.value = new Set(); rubrique.value = null; texte.value = '' }

/* ------------------------------------------------------------------ composer */

function toucherArticle(p) {
  if (aComposer(p)) { emit('compose', p); return }
  const v = versions(p)
  const lot = { uid: ++seq, product: p, version: v[0] || null, qte: 1, mods: [], notes: [] }
  lots.value.push(lot)
  ouvrir(p, lot.version?.id || 0)
}

function ouvrir(p, versionId = null) {
  courant.value = p
  attente.value = null
  ouvertLot.value = versionId
  toutEffacer()
}

/** Une unité de plus sur cette version : elle rejoint le lot nu s'il en existe un. */
function ajouterUn(p, version) {
  const vid = version?.id || 0
  const nu = parVersion(p, vid).find(l => marques(l) === 0)
  if (nu) nu.qte += 1
  else lots.value.push({ uid: ++seq, product: p, version, qte: 1, mods: [], notes: [] })
  ouvertLot.value = vid
}

/** Une de moins : on prend dans le lot le moins chargé, pour n'effacer aucune consigne. */
function retirerUn(p, version) {
  const l = parVersion(p, version?.id || 0).slice().sort((a, b) => marques(a) - marques(b))[0]
  if (!l) return
  if (l.qte > 1) l.qte -= 1
  else lots.value.splice(lots.value.indexOf(l), 1)
}

function retirerArticle(p) {
  lots.value = lots.value.filter(l => l.product.id !== p.id)
  courant.value = null
}

/* ------------------------------------------------------------------ options et remarques */

/*
    Une seule question, la même pour les suppléments et les remarques : « pour combien
    de ces N ? ». C'est elle qui évite l'erreur classique — la consigne posée sur les
    quatre alors que le client n'en voulait qu'une.
*/
function toucher(l, quoi) {
  if (l.qte === 1 || quoi.pose) { appliquer(l, quoi); attente.value = null; return }
  attente.value = { ...quoi, uid: l.uid }
}

function appliquer(l, quoi) {
  if (quoi.type === 'mod') {
    const i = l.mods.findIndex(m => m.id === quoi.valeur.id)
    if (i >= 0) { l.mods.splice(i, 1); return }
    // Dans un groupe à choix unique, la nouvelle option remplace l'ancienne.
    if (quoi.groupe && (!quoi.groupe.multiple || quoi.groupe.maxSelect === 1))
      l.mods = l.mods.filter(m => !quoi.groupe.modifiers.some(x => x.id === m.id))
    l.mods.push({ id: quoi.valeur.id, name: quoi.valeur.name, priceDelta: Number(quoi.valeur.priceDelta), quantity: 1 })
  } else {
    const i = l.notes.indexOf(quoi.valeur)
    i >= 0 ? l.notes.splice(i, 1) : l.notes.push(quoi.valeur)
  }
}

/** k unités se détachent du lot et emportent le choix ; le reste ne bouge pas. */
function scinder(l, k, quoi) {
  const neuf = { uid: ++seq, product: l.product, version: l.version, qte: k, mods: [...l.mods], notes: [...l.notes] }
  l.qte -= k
  lots.value.splice(lots.value.indexOf(l) + 1, 0, neuf)
  appliquer(neuf, quoi)
  attente.value = null
  choisi[l.version?.id || 0] = neuf.uid
}

/* ------------------------------------------------------------------ le panneau */

const versionsCourantes = computed(() => courant.value ? versions(courant.value) : [])
const lotsCourants = computed(() => courant.value ? lotsDe(courant.value) : [])
const totalCourant = computed(() => lotsCourants.value.reduce((s, l) => s + l.qte, 0))

/** Les versions effectivement posées, dans l'ordre de l'axe ; [null] pour un article sans déclinaison. */
const groupes = computed(() => {
  if (!courant.value) return []
  const v = versionsCourantes.value.filter(x => parVersion(courant.value, x.id).length)
  return v.length ? v : (lotsCourants.value.length ? [null] : [])
})

function lotsDuGroupe(v) { return parVersion(courant.value, v?.id || 0) }

function actifDuGroupe(v) {
  const l = lotsDuGroupe(v)
  const vid = v?.id || 0
  if (!l.some(x => x.uid === choisi[vid])) choisi[vid] = l[0]?.uid
  return l.find(x => x.uid === choisi[vid]) || l[0]
}

/* Un lot déplié à la fois : les suppléments répétés pour chaque pâte ne se lisent pas. */
function estDeplie(v) {
  if (attente.value) {
    const la = lots.value.find(x => x.uid === attente.value.uid)
    if (la) return (la.version?.id || 0) === (v?.id || 0)
  }
  if (groupes.value.length === 1) return true
  if (ouvertLot.value === false) return false
  const ids = groupes.value.map(g => g?.id || 0)
  return (ids.includes(ouvertLot.value) ? ouvertLot.value : ids[0]) === (v?.id || 0)
}
function basculerLot(v) { ouvertLot.value = estDeplie(v) ? false : (v?.id || 0) }

const resume = (l) => [...l.mods.map(m => '+ ' + m.name), ...l.notes].join(', ')
const RANGS = '①②③④⑤⑥⑦⑧⑨⑩'

/* ------------------------------------------------------------------ sortie */

const relecture = ref(false)

/** La commande dans les mots du client, à relire à voix haute avant de valider. */
const phrase = computed(() => {
  const blocs = []
  for (const l of lots.value) {
    const cle = l.product.id + '|' + (l.version?.id || 0)
    let b = blocs.find(x => x.cle === cle)
    if (!b) { b = { cle, product: l.product, version: l.version, unites: [] }; blocs.push(b) }
    b.unites.push(l)
  }
  const dits = blocs.map(b => {
    const n = b.unites.reduce((s, l) => s + l.qte, 0)
    let s = n + ' ' + b.product.name + (b.version ? ' en ' + b.version.name.toLowerCase() : '')
    const det = b.unites.filter(l => marques(l)).map(l => (b.unites.length > 1 ? l.qte + ' ' : '') + resume(l).toLowerCase())
    if (det.length) s += ' — ' + det.join(' ; ')
    return s
  })
  const n = compteSandwichs.value
  return dits.join(' · ') + '. Soit ' + n + ' sandwich' + (n > 1 ? 's' : '') + ', ' + fmt(totalCommande.value, true) + '.'
})

function valider() {
  emit('confirm', lots.value.map(l => ({
    product: l.product,
    quantity: l.qte,
    modifiers: l.mods,
    /* La remarque est un texte, séparé par des virgules : c'est la forme que la boîte
       « Remarques » du panier relit pour re-cocher les cases. */
    note: l.notes.join(', '),
    variantValue: l.version
  })))
}
</script>

<template>
  <Modal size="full" :closable="false" @close="emit('close')">
    <template #head>
      <h2>Assistant commande</h2>
      <div class="annonce">
        <span class="eyebrow">Annoncé</span>
        <button v-for="n in [1, 2, 3, 4, 5, 6, 8, 10]" :key="n" class="pav" :class="{ on: annonce === n }"
                @click="annonce = annonce === n ? null : n">{{ n }}</button>
        <span class="jauge num" :class="annonce == null ? '' : compteJuste ? 'ok' : 'ecart'">
          {{ annonce == null ? compteSandwichs : compteSandwichs + ' / ' + annonce }}
          <i>{{ compteSandwichs > 1 ? 'sandwichs' : 'sandwich' }}</i>
        </span>
      </div>
      <button class="btn ghost icon" @click="emit('close')" aria-label="Fermer"><Icon name="close" :size="18" /></button>
    </template>

    <div class="assistant">
      <!-- ---------------------------------------------------------- trouver -->
      <section class="trouver scroll">
        <div class="groupe">
          <span class="eyebrow">Rubrique</span>
          <div class="pastilles">
            <button v-for="c in catalog.categories" :key="c.id" class="past rub" :class="{ on: rubrique === c.id }"
                    @click="rubrique = rubrique === c.id ? null : c.id">{{ c.name }}</button>
          </div>
        </div>

        <div class="groupe" v-if="ingredients.length">
          <span class="eyebrow">Ce que le client a dit</span>
          <div class="pastilles">
            <button v-for="i in ingredients" :key="i.id" class="past" :class="{ on: filtres.has(i.id), mort: !filtres.has(i.id) && !restant(i.id) }"
                    @click="basculerIngredient(i.id)">{{ i.name }}<small class="num">{{ restant(i.id) }}</small></button>
          </div>
        </div>

        <div class="ligne-recherche">
          <input class="input" v-model="texte" type="search" placeholder="ou tapez le début d’un nom…" aria-label="Chercher un article" />
          <button class="btn" @click="toutEffacer">Tout effacer</button>
        </div>

        <div class="combien">
          <b>{{ surFavoris ? 'Favoris' : resultats.length + (resultats.length > 1 ? ' articles' : ' article') }}</b>
          <span class="muted small" v-if="surFavoris">— ou cherchez ci-dessus</span>
          <span class="muted small" v-else-if="resultats.length === 1">— touchez-le pour le composer</span>
          <span class="muted small" v-else-if="resultats.length > 24">— précisez pour réduire</span>
        </div>

        <div class="grille">
          <button v-for="p in resultats.slice(0, 60)" :key="p.id" class="plat" @click="toucherArticle(p)">
            <b>{{ p.name }}</b>
            <i>{{ catalog.categories.find(c => c.id === p.categoryId)?.name }}</i>
            <span class="prix num">{{ fmt(versions(p)[0]?.price ?? p.price) }}</span>
          </button>
          <p v-if="!resultats.length" class="empty">Aucun article ne porte tout cela ensemble.</p>
        </div>
      </section>

      <!-- ---------------------------------------------------------- la commande -->
      <aside class="ardoise">
        <div class="ard-tete"><span class="eyebrow">La commande</span></div>
        <div class="ard-corps scroll">
          <p v-if="!lots.length" class="ard-vide">Rien encore.<br />Cherchez à gauche, la commande se remplit ici.</p>
          <div v-for="p in [...new Map(lots.map(l => [l.product.id, l.product])).values()]" :key="p.id" class="bloc">
            <button class="bloc-tete" @click="ouvrir(p)">
              <span class="n num">{{ lotsDe(p).reduce((s, l) => s + l.qte, 0) }}×</span>
              <b>{{ p.name }}</b>
            </button>
            <div v-for="(l, k) in lotsDe(p)" :key="l.uid" class="unite" @click="ouvrir(p, l.version?.id || 0)">
              <span class="rang num">{{ lotsDe(p).length > 1 ? RANGS[k] || (k + 1) : l.qte + '×' }}</span>
              <span class="det">
                <em v-if="l.version">{{ l.version.name }}</em>
                <span v-if="marques(l)">
                  <span v-for="m in l.mods" :key="m.id" class="marque supp">+ {{ m.name }}</span>
                  <span v-for="n in l.notes" :key="n" class="marque note">{{ n }}</span>
                </span>
                <span v-else class="rien">rien de particulier</span>
              </span>
              <span class="prix num">{{ fmt(prixUnite(l) * l.qte) }}</span>
            </div>
          </div>
        </div>
      </aside>
    </div>

    <template #foot>
      <span class="pied-total">Total <b class="num">{{ fmt(totalCommande, true) }}</b></span>
      <button class="btn lg" :disabled="!lots.length" @click="relecture = true">Relire au client</button>
      <button class="btn lg primary" :disabled="!lots.length || !compteJuste" @click="valider">
        Ajouter à la commande
      </button>
    </template>
  </Modal>

  <!-- ------------------------------------------------------------ un article -->
  <Modal v-if="courant" size="md" :title="courant.name" @close="courant = null">
    <div class="fiche">
      <div class="groupe">
        <span class="eyebrow">Combien{{ versionsCourantes.length ? ', et de quelle version' : '' }}</span>
        <div class="repartition">
          <div v-for="v in (versionsCourantes.length ? versionsCourantes : [null])" :key="v?.id || 0"
               class="part" :class="{ pose: parVersion(courant, v?.id || 0).length }">
            <span class="nom">{{ v ? v.name : courant.name }}</span>
            <span class="tarif num">{{ fmt(v ? v.price : courant.price) }}</span>
            <div class="qte">
              <button :disabled="!parVersion(courant, v?.id || 0).length" @click="retirerUn(courant, v)">−</button>
              <span class="num">{{ parVersion(courant, v?.id || 0).reduce((s, l) => s + l.qte, 0) }}</span>
              <button @click="ajouterUn(courant, v)">+</button>
            </div>
          </div>
        </div>
        <p class="bilan small muted">
          {{ totalCourant === 0 ? 'Aucune unité — cet article sortira de la commande.'
             : totalCourant + ' unité' + (totalCourant > 1 ? 's' : '') + ' en tout.' }}
        </p>
      </div>

      <div v-for="v in groupes" :key="v?.id || 0" class="lot" :class="{ plie: !estDeplie(v) }">
        <button class="lot-tete" @click="basculerLot(v)">
          <b>{{ lotsDuGroupe(v).reduce((s, l) => s + l.qte, 0) }} × {{ v ? v.name : courant.name }}</b>
          <i v-if="!estDeplie(v)">{{ lotsDuGroupe(v).map(l => resume(l) || 'nature').join(' · ') }}</i>
          <span class="num">{{ fmt(lotsDuGroupe(v).reduce((s, l) => s + prixUnite(l) * l.qte, 0)) }}</span>
          <em>{{ estDeplie(v) ? '▾' : '▸' }}</em>
        </button>

        <template v-if="estDeplie(v)">
          <div v-if="lotsDuGroupe(v).length > 1" class="onglets">
            <button v-for="(l, k) in lotsDuGroupe(v)" :key="l.uid" class="onglet"
                    :class="{ on: actifDuGroupe(v)?.uid === l.uid }"
                    @click="choisi[v?.id || 0] = l.uid; attente = null">
              <b>{{ RANGS[k] || (k + 1) }}</b> {{ l.qte }}× {{ resume(l) || 'nature' }}
            </button>
          </div>

          <div v-if="attente && attente.uid === actifDuGroupe(v)?.uid" class="question">
            <p><b>{{ attente.libelle }}</b> — pour combien de ces {{ actifDuGroupe(v).qte }} ?</p>
            <div class="choix">
              <button class="btn primary" @click="appliquer(actifDuGroupe(v), attente); attente = null">
                Tous les {{ actifDuGroupe(v).qte }}
              </button>
              <button v-for="k in actifDuGroupe(v).qte - 1" :key="k" class="btn"
                      @click="scinder(actifDuGroupe(v), k, attente)">
                {{ k === 1 ? 'Un seul' : k + ' d’entre eux' }}
              </button>
            </div>
          </div>

          <div v-for="g in (courant.modifierGroups || [])" :key="g.id" class="groupe">
            <span class="eyebrow">{{ g.name }}</span>
            <div class="pastilles">
              <button v-for="m in g.modifiers.filter(x => x.active !== false)" :key="m.id" class="past ptt"
                      :class="{ on: actifDuGroupe(v)?.mods.some(x => x.id === m.id) }"
                      @click="toucher(actifDuGroupe(v), { type: 'mod', valeur: m, groupe: g, libelle: m.name,
                                                          pose: actifDuGroupe(v).mods.some(x => x.id === m.id) })">
                {{ m.name }}<small class="num" v-if="Number(m.priceDelta)">+{{ fmt(m.priceDelta) }}</small>
              </button>
            </div>
          </div>

          <div class="groupe" v-if="notes.length">
            <span class="eyebrow">Remarques cuisine</span>
            <div class="pastilles">
              <button v-for="n in notes" :key="n.id" class="past ptt"
                      :class="{ on: actifDuGroupe(v)?.notes.includes(n.label) }"
                      @click="toucher(actifDuGroupe(v), { type: 'note', valeur: n.label, libelle: n.label,
                                                          pose: actifDuGroupe(v).notes.includes(n.label) })">
                {{ n.label }}
              </button>
            </div>
          </div>
        </template>
      </div>
    </div>

    <template #foot>
      <button class="btn lg danger" @click="retirerArticle(courant)">Retirer cet article</button>
      <button class="btn lg primary" @click="courant = null">C’est bon</button>
    </template>
  </Modal>

  <!-- ------------------------------------------------------------ relecture -->
  <Modal v-if="relecture" size="md" title="À relire au client" @close="relecture = false">
    <p class="phrase">« Je vous répète : {{ phrase }} »</p>
    <template #foot>
      <button class="btn lg" @click="relecture = false">Corriger</button>
      <button class="btn lg primary" @click="relecture = false; valider()">C’est exact</button>
    </template>
  </Modal>
</template>

<style scoped>
.annonce { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; margin-left: auto; }
.pav { min-width: 36px; height: 36px; border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface); font-variant-numeric: tabular-nums; }
.pav.on { background: var(--ink); color: var(--surface); border-color: var(--ink); }
.jauge { display: inline-flex; align-items: baseline; gap: 5px; padding: 6px 13px; border-radius: 999px; border: 1px solid var(--line-2); font-size: 17px; font-weight: 700; }
.jauge i { font-style: normal; font-size: 11.5px; font-weight: 500; color: var(--ink-3); }
.jauge.ok { border-color: var(--pay); color: var(--pay-2); }
.jauge.ecart { border-color: var(--warn); color: var(--warn); }

.assistant { display: grid; grid-template-columns: minmax(0, 1fr) 360px; gap: 0; height: 100%; min-height: 0; margin: -20px; }
.trouver { padding: 16px 18px; min-width: 0; overflow-y: auto; }
.groupe + .groupe { margin-top: 13px; }
.groupe .eyebrow { display: block; margin-bottom: 7px; }
.pastilles { display: flex; flex-wrap: wrap; gap: 6px; }
.past { min-height: 42px; padding: 9px 15px; border: 1px solid var(--line-2); border-radius: 999px; background: var(--surface); font-size: 14.5px; font-weight: 500; }
.past:hover { border-color: var(--ink); }
.past.on { background: var(--brand); border-color: var(--brand); color: #fff; }
.past.rub.on { background: var(--ink); border-color: var(--ink); color: var(--surface); }
.past.mort { opacity: .35; }
.past small { opacity: .6; margin-left: 6px; font-size: 12px; }
.past.ptt { min-height: 38px; padding: 7px 13px; font-size: 13.5px; }

.ligne-recherche { display: flex; gap: 9px; margin-top: 12px; }
.ligne-recherche .input { flex: 1; }
.combien { margin: 15px 0 8px; display: flex; align-items: baseline; gap: 9px; }
.grille { display: grid; grid-template-columns: repeat(auto-fill, minmax(206px, 1fr)); gap: 8px; }
.plat { display: flex; flex-direction: column; align-items: flex-start; gap: 3px; text-align: left; min-height: 74px;
        padding: 11px 13px; border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface); }
.plat:hover { border-color: var(--brand); }
.plat b { font-size: 15px; font-weight: 650; line-height: 1.2; }
.plat i { font-style: normal; font-size: 11.5px; color: var(--ink-3); }
.plat .prix { margin-top: auto; font-size: 13.5px; color: var(--brand-2); }

.ardoise { display: flex; flex-direction: column; min-height: 0; border-left: 1px solid var(--line); background: var(--surface-2); }
.ard-tete { padding: 13px 15px 9px; border-bottom: 1px solid var(--line); }
.ard-corps { flex: 1; overflow-y: auto; padding: 10px 12px; display: flex; flex-direction: column; gap: 8px; }
.ard-vide { color: var(--ink-4); text-align: center; padding: 40px 10px; font-size: 13.5px; }
.bloc { border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface); overflow: hidden; }
.bloc-tete { display: flex; align-items: baseline; gap: 8px; width: 100%; text-align: left; padding: 9px 12px 7px; }
.bloc-tete .n { color: var(--brand-2); font-size: 14px; }
.bloc-tete b { font-size: 14.5px; font-weight: 650; line-height: 1.2; }
.unite { display: flex; gap: 8px; align-items: flex-start; width: 100%; text-align: left; padding: 8px 12px; border-top: 1px solid var(--line); cursor: pointer; }
.unite:hover { background: var(--surface-3); }
.unite .rang { font-size: 12px; color: var(--ink-4); min-width: 16px; }
.unite .det { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 3px; }
.unite .det em { font-style: normal; font-size: 11px; letter-spacing: .06em; text-transform: uppercase; color: var(--ink-3); }
.unite .rien { font-size: 12.5px; color: var(--ink-4); }
.marque { display: inline-block; font-size: 12px; padding: 2px 8px; border-radius: 999px; margin: 0 4px 3px 0; }
.marque.supp { background: var(--brand-soft); color: var(--brand-2); }
.marque.note { background: var(--surface-3); color: var(--ink-2); }
.unite .prix { font-size: 13px; white-space: nowrap; }
.pied-total { margin-right: auto; font-size: 14px; color: var(--ink-3); }
.pied-total b { font-size: 21px; color: var(--ink); margin-left: 8px; }

/* ---------- la fiche d'un article ---------- */
.fiche { display: grid; gap: 15px; }
.repartition { display: flex; flex-wrap: wrap; gap: 8px; }
.part { display: flex; flex-direction: column; align-items: flex-start; gap: 6px; padding: 10px 12px;
        border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface-2); }
.part.pose { border-color: var(--brand); background: var(--surface); }
.part .nom { font-size: 14.5px; font-weight: 650; }
.part .tarif { font-size: 12.5px; color: var(--ink-3); }
.qte { display: flex; align-items: center; border: 1px solid var(--line-2); border-radius: var(--r-sm); overflow: hidden; }
.qte button { width: 44px; height: 44px; font-size: 20px; background: var(--surface); }
.qte button:hover { background: var(--surface-3); }
.qte button:disabled { opacity: .3; }
.qte span { min-width: 46px; text-align: center; font-size: 17px; }
.bilan { margin: 8px 0 0; }

.lot { border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface-2); padding: 12px 13px; display: grid; gap: 11px; }
.lot.plie { padding: 0; background: var(--surface); }
.lot-tete { display: flex; align-items: baseline; gap: 10px; width: 100%; text-align: left; }
.lot.plie .lot-tete { padding: 11px 13px; }
.lot-tete b { font-size: 15px; font-weight: 650; }
.lot-tete i { font-style: normal; font-size: 12.5px; color: var(--ink-3); flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.lot-tete .num { font-size: 13px; color: var(--ink-3); margin-left: auto; }
.lot-tete em { font-style: normal; color: var(--ink-3); font-size: 13px; }
.onglets { display: flex; flex-wrap: wrap; gap: 6px; }
.onglet { padding: 7px 12px; border: 1px solid var(--line-2); border-radius: 999px; background: var(--surface); font-size: 12.5px; text-align: left; }
.onglet b { color: var(--brand-2); }
.onglet.on { background: var(--ink); border-color: var(--ink); color: var(--surface); }
.onglet.on b { color: var(--surface); }
.question { border: 1px solid var(--brand); border-radius: var(--r-sm); background: var(--brand-soft); padding: 12px 13px; display: grid; gap: 10px; }
.question p { margin: 0; font-size: 14.5px; }
.question .choix { display: flex; gap: 8px; flex-wrap: wrap; }
.phrase { margin: 0; font-size: 16px; line-height: 1.7; }

@media (max-width: 900px) {
  .assistant { grid-template-columns: 1fr; grid-template-rows: minmax(0, 1fr) auto; }
  .ardoise { border-left: 0; border-top: 1px solid var(--line); max-height: 42vh; }
}
</style>
