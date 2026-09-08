<script setup>
/** Options / suppléments picker, and menu composition (components) for MENU products. */
import { computed, reactive, ref } from 'vue'
import Modal from '../common/Modal.vue'
import { fmt, add, mul } from '../../utils/money'
import { useCatalogStore } from '../../stores/catalog'
import { useUiStore } from '../../stores/ui'

const props = defineProps({ product: Object, initial: Object, stock: { type: Object, default: () => ({}) } })
const emit = defineEmits(['close', 'confirm'])
const catalog = useCatalogStore(); const ui = useUiStore()
const isMenu = computed(() => props.product.productType === 'MENU')

/*
    Variante de l'article : la rangee du haut, avant les options.

    Elle vient en premier parce qu'elle decide du PRIX de la ligne, pas d'un supplement :
    « Pizza Thon Large » se vend 18 DT, ce n'est pas « Pizza Thon » plus trois dinars.

    Une version sans prix apparait grisee au lieu de disparaitre : c'est le cas d'une
    valeur ajoutee a l'axe apres le parametrage de l'article. Le gerant la voit, comprend
    qu'il lui reste a la tarifer, et ne cherche pas pourquoi elle manque.
*/
const axe = computed(() => catalog.variants.find(v => v.id === props.product.variantId) || null)
const prixVariante = computed(() => Object.fromEntries((props.product.variantPrices || []).map(p => [p.variantValueId, Number(p.price)])))
/*
    La photo de chaque version, quand elle en a une.

    C'est ici qu'elle sert le plus : le caissier choisit entre deux versions qui ne se
    reconnaissent pas a leur nom - un T-shirt noir et un blanc, une pate cereale et une
    pate normale. Sans photo de version, on retombe sur celle de l'article ; sans elle
    non plus, le bouton reste ce qu'il etait, un nom et un prix.
*/
const photoVariante = computed(() => Object.fromEntries(
  (props.product.variantPrices || []).filter(p => p.imageUrl).map(p => [p.variantValueId, p.imageUrl])))
// Declaree avant les versions : leur calcul s'evalue des le choix de la version par
// defaut, quelques lignes plus bas, et lit deja la quantite.
const quantity = ref(props.initial?.quantity || 1)

/*
    Ce qu'une version consomme, et ce qu'il en reste.

    Une version peut ne pas porter son propre compteur et tirer sur une autre : << Double
    Normale >> consomme deux pates normales. C'est donc le compteur de la SOURCE qu'il
    faut regarder, et le pas qu'il faut comparer - sinon << Double Normale >> resterait
    proposee alors qu'il ne reste qu'une pate.

    Le grisage n'est qu'une politesse : c'est le serveur qui refuse la vente, verrou pose
    sur le compteur. Ici on evite au caissier de composer devant le client une commande
    qui sera refusee ensuite.
*/
const versions = computed(() => (axe.value?.values || []).filter(v => v.active)
  .map(v => {
    const photo = photoVariante.value[v.id] || props.product.imageUrl || null
    const porteur = v.stockManaged ? v.id : (v.stockSourceId || null)
    const pas = Number(v.stockStep || 1)
    const reste = porteur ? Number(props.stock?.[porteur] ?? Infinity) : Infinity
    /*
        << epuisee >> ne depend PAS de la quantite demandee : une version est epuisee
        quand il n'en reste pas de quoi en servir UNE. Faire dependre le grisage de la
        quantite eteignait la version choisie des qu'on montait le compteur - elle
        semblait alors s'etre deselectionnee toute seule, et le regard partait sur la
        premiere version encore allumee.

        La quantite, elle, est bornee plus bas : c'est la version CHOISIE qui decide de
        son maximum, et rien ne change de soi-meme.
    */
    const max = porteur == null ? Infinity : Math.floor((reste + 1e-9) / pas)
    return { ...v, price: prixVariante.value[v.id] || 0, photo, porteur, reste, pas, max, epuisee: max < 1 }
  }))
const version = ref(props.initial?.variantValueId
  || props.product.defaultVariantValueId
  || versions.value.find(v => v.price > 0)?.id
  || null)
const versionChoisie = computed(() => versions.value.find(v => v.id === version.value) || null)
/*
    Ce que la version CHOISIE autorise. C'est elle qui commande, et elle seule : changer
    de version parce que celle-ci manque serait servir au client autre chose que ce qu'il
    a demande, sans le lui dire.
*/
const maxChoisi = computed(() => versionChoisie.value ? versionChoisie.value.max : Infinity)
const borne = computed(() => Number.isFinite(maxChoisi.value))
const tropDemande = computed(() => borne.value && quantity.value > maxChoisi.value)
function plus() {
  if (borne.value && quantity.value >= maxChoisi.value) return
  quantity.value++
}
const note = ref(props.initial?.note || '')
/* Selection : groupId -> { modifierId: quantite }. Un compteur et non un simple
   ensemble, car dans un groupe sans maximum la meme option peut etre ajoutee
   plusieurs fois (« 3 x fromage »). */
const sel = reactive({})
for (const g of props.product.modifierGroups || []) {
  sel[g.id] = {}
  for (const m of (props.initial?.modifiers || [])) {
    if (g.modifiers.some(x => x.id === m.id)) sel[g.id][m.id] = m.quantity || 1
  }
}
/* Maximum a 0 = illimite : c'est le reglage qui autorise la repetition. */
const repeatable = (g) => g.multiple && !g.maxSelect
/* Un groupe dont le maximum effectif vaut 1 est a choix unique, que la case
   « choix multiple » soit cochee ou non : c'est le maximum qui fait foi.
   Sans cela, « multiple + max 1 » refusait la seconde option au lieu de
   remplacer la premiere. */
const singleChoice = (g) => !g.multiple || g.maxSelect === 1
const picked = (g) => Object.values(sel[g.id]).reduce((s, n) => s + n, 0)
// menu components: componentId -> [{productId, quantity, modifiers}]
const comps = reactive({})
for (const c of props.product.menuComponents || []) comps[c.id] = []
if (props.initial?.components) for (const c of props.product.menuComponents || []) comps[c.id] = props.initial.components.filter(x => c.options.some(o => o.productId === x.productId)).map(x => ({ ...x }))
const activeComponent = ref(null) // {compId, option, product} when choosing sub-options
const subSel = reactive({})

function toggle(g, m) {
  const s = sel[g.id]
  if (repeatable(g)) { s[m.id] = (s[m.id] || 0) + 1; return }   // chaque appui en ajoute un
  if (singleChoice(g)) {
    // Choix unique : la nouvelle option remplace l'ancienne d'un seul geste.
    const dejaPris = !!s[m.id]
    for (const k of Object.keys(s)) delete s[k]
    if (!dejaPris) s[m.id] = 1
    return
  }
  if (s[m.id]) { delete s[m.id]; return }
  const max = g.maxSelect
  if (picked(g) >= max) { ui.info(`Maximum ${max} option(s) pour « ${g.name} »`); return }
  s[m.id] = 1
}
/* Retrait d'une unite : sans cela, un appui de trop obligerait a tout refaire. */
function less(g, m) {
  const s = sel[g.id]
  if (!s[m.id]) return
  if (s[m.id] > 1) s[m.id]--
  else delete s[m.id]
}
function chooseOption(comp, opt) {
  const product = catalog.productsById[opt.productId]
  if (!product || !opt.available) return
  const current = comps[comp.id]
  const count = current.reduce((s, x) => s + x.quantity, 0)
  if (comp.quantity === 1) comps[comp.id] = []
  else if (count >= comp.quantity) { comps[comp.id] = current.slice(1) }
  const entry = { productId: opt.productId, product, quantity: 1, priceDelta: Number(opt.priceDelta), modifiers: [] }
  comps[comp.id].push(entry)
  if ((product.modifierGroups || []).some(g => g.required)) openSub(comp, entry)
}
function openSub(comp, entry) {
  activeComponent.value = { comp, entry }
  for (const k of Object.keys(subSel)) delete subSel[k]
  for (const g of entry.product.modifierGroups) subSel[g.id] = new Set(entry.modifiers.map(m => m.id))
}
function subToggle(g, m) {
  const s = subSel[g.id]
  if (singleChoice(g)) {                      // meme regle que dans la boite principale
    const dejaPris = s.has(m.id)
    s.clear()
    if (!dejaPris) s.add(m.id)
    return
  }
  if (s.has(m.id)) { s.delete(m.id); return }
  const max = g.maxSelect || 99
  if (s.size >= max) return
  s.add(m.id)
}
function subOk() {
  const e = activeComponent.value.entry
  e.modifiers = []
  for (const g of e.product.modifierGroups) for (const m of g.modifiers) if (subSel[g.id].has(m.id)) e.modifiers.push({ id: m.id, name: m.name, priceDelta: Number(m.priceDelta), quantity: 1 })
  activeComponent.value = null
}
const modifiers = computed(() => {
  const out = []
  for (const g of props.product.modifierGroups || []) for (const m of g.modifiers) {
    const n = sel[g.id][m.id] || 0
    if (n > 0) out.push({ id: m.id, name: m.name, priceDelta: Number(m.priceDelta), quantity: n })
  }
  return out
})
const components = computed(() => Object.values(comps).flat())
const unit = computed(() => {
  let u = versionChoisie.value ? versionChoisie.value.price : Number(props.product.price)
  for (const m of modifiers.value) u = add(u, mul(m.priceDelta, m.quantity))
  for (const c of components.value) u = add(u, mul(add(c.priceDelta, c.modifiers.reduce((s, m) => add(s, m.priceDelta), 0)), c.quantity))
  return u
})
const problems = computed(() => {
  const p = []
  for (const g of props.product.modifierGroups || []) { const n = picked(g); if (g.required && n < Math.max(1, g.minSelect)) p.push(`Choisissez « ${g.name} »`); else if (n > 0 && n < g.minSelect) p.push(`« ${g.name} » : minimum ${g.minSelect}`) }
  for (const c of props.product.menuComponents || []) { const n = comps[c.id].reduce((s, x) => s + x.quantity, 0); if (n !== c.quantity) p.push(`Choisissez ${c.quantity} « ${c.name} »`) }
  return p
})
function confirm() {
  if (problems.value.length) return ui.error(problems.value[0])
  if (axe.value && !versionChoisie.value) return ui.error(`Choisissez « ${axe.value.name} »`)
  // La version choisie decide. Rien n'est bascule vers une autre : on refuse, on nomme
  // la pate et son reste, et le caissier tranche - moins d'articles, ou une autre pate.
  if (tropDemande.value || versionChoisie.value?.epuisee)
    return ui.error(`Stock insuffisant : il reste ${versionChoisie.value.reste} « ${versionChoisie.value.name} », soit ${maxChoisi.value} au maximum.`)
  emit('confirm', { quantity: quantity.value, modifiers: modifiers.value, components: components.value, note: note.value,
                    variantValue: versionChoisie.value })
}
</script>
<template>
  <Modal size="md" @close="emit('close')">
    <template #head>
      <div class="grow"><h2>{{ product.name }}</h2><div class="muted small">{{ isMenu ? 'Composez le menu' : (axe ? axe.name + ' & options' : 'Options & suppléments') }} — {{ fmt(unit, true) }}</div></div>
      <div class="qty row gap-4"><button class="btn lg icon" @click="quantity=Math.max(1,quantity-1)">−</button><span class="qv num" :class="{ trop: tropDemande }">{{ quantity }}</span><button class="btn lg icon" :disabled="borne && quantity >= maxChoisi" :title="borne ? 'Stock : ' + maxChoisi + ' au maximum' : ''" @click="plus">+</button></div>
    </template>
    <!-- Les versions passent avant les options : elles decident du prix, pas d'un ajout. -->
    <div v-if="axe && !activeComponent" class="versions">
      <div class="gname">{{ axe.name }} <span class="badge">version</span></div>
      <div class="opts">
        <button v-for="v in versions" :key="v.id" class="opt version"
                :class="{ on: version === v.id, sansprix: !v.price, epuisee: v.epuisee }" :disabled="!v.price || v.epuisee"
                :title="!v.price ? 'Aucun prix : à renseigner dans la fiche article'
                        : v.epuisee ? 'Stock épuisé — il reste ' + v.reste : ''"
                @click="version = v.id">
          <img v-if="v.photo" class="vue" :src="v.photo" alt="" draggable="false" />
          <span>{{ v.name }}</span>
          <span v-if="v.epuisee" class="delta epuise">épuisé</span>
          <span v-else class="delta num">{{ fmt(v.price) }}</span>
        </button>
      </div>
      <!-- Le stock de la version choisie, dit ici : le caissier voit ce qui le limite
           avant de monter la quantité, et non après avoir tout composé. -->
      <p v-if="borne" class="restant" :class="{ trop: tropDemande }">
        <template v-if="tropDemande">
          Stock insuffisant : il reste {{ versionChoisie.reste }} « {{ versionChoisie.name }} »,
          soit {{ maxChoisi }} au maximum{{ versionChoisie.pas > 1 ? ' (' + versionChoisie.pas + ' par article)' : '' }}.
        </template>
        <template v-else>
          Il reste {{ versionChoisie.reste }} « {{ versionChoisie.name }} » — {{ maxChoisi }} au maximum{{ versionChoisie.pas > 1 ? ' (' + versionChoisie.pas + ' par article)' : '' }}.
        </template>
      </p>
    </div>

    <div v-if="activeComponent" class="sub">
      <div class="row between mb-8"><h3>{{ activeComponent.entry.product.name }} — options</h3><button class="btn sm" @click="subOk">Terminer</button></div>
      <div v-for="g in activeComponent.entry.product.modifierGroups" :key="g.id" class="group">
        <div class="gname">{{ g.name }} <span class="badge" v-if="g.required">obligatoire</span></div>
        <div class="opts"><button v-for="m in g.modifiers" :key="m.id" class="opt" :class="{ on: subSel[g.id].has(m.id) }" @click="subToggle(g, m)"><span>{{ m.name }}</span><span v-if="Number(m.priceDelta)" class="delta">+{{ fmt(m.priceDelta) }}</span></button></div>
      </div>
    </div>
    <template v-else>
      <div v-for="c in product.menuComponents" :key="c.id" class="group">
        <div class="gname">{{ c.name }} <span class="badge accent">{{ c.quantity }} au choix</span></div>
        <div class="opts">
          <button v-for="o in c.options" :key="o.productId" class="opt" :class="{ on: comps[c.id].some(x => x.productId===o.productId), off: !o.available }" @click="chooseOption(c, o)">
            <span>{{ o.productName }}</span><span v-if="Number(o.priceDelta)" class="delta">+{{ fmt(o.priceDelta) }}</span>
            <span v-if="comps[c.id].find(x => x.productId===o.productId)?.modifiers.length" class="tiny">({{ comps[c.id].find(x => x.productId===o.productId).modifiers.map(m=>m.name).join(', ') }})</span>
          </button>
        </div>
        <div v-for="e in comps[c.id].filter(x => x.product.modifierGroups?.length)" :key="e.productId" class="row mt-8"><button class="btn sm soft" @click="openSub(c, e)">Options {{ e.product.name }} ›</button></div>
      </div>
      <div v-for="g in product.modifierGroups" :key="g.id" class="group">
        <div class="gname">{{ g.name }} <span class="badge" :class="g.required ? 'accent' : ''">{{ g.required ? 'obligatoire' : 'facultatif' }}{{ g.multiple && g.maxSelect ? ` · max ${g.maxSelect}` : (repeatable(g) ? ' · répétable' : '') }}</span></div>
        <div class="opts">
          <button v-for="m in g.modifiers" :key="m.id" class="opt" :class="{ on: sel[g.id][m.id] > 0 }" @click="toggle(g, m)">
            <span class="oname">{{ m.name }}</span>
            <span v-if="Number(m.priceDelta)" class="delta">+{{ fmt(m.priceDelta) }}</span>
            <template v-if="sel[g.id][m.id] > 0 && repeatable(g)">
              <b class="mult num">×{{ sel[g.id][m.id] }}</b>
              <span class="less" role="button" title="Retirer un" @click.stop="less(g, m)">−</span>
            </template>
          </button>
        </div>
      </div>
      <div class="field mt-8"><label>Remarque cuisine</label><input class="input" v-model="note" placeholder="ex. bien cuit, sans sel…" /></div>
    </template>
    <template #foot>
      <div class="grow"><span class="muted">Prix unitaire</span> <b class="num" style="font-size:20px">{{ fmt(unit, true) }}</b></div>
      <button class="btn lg" @click="emit('close')">Annuler</button>
      <button class="btn success xl" :disabled="!!activeComponent || tropDemande || (versionChoisie && versionChoisie.epuisee)" @click="confirm">AJOUTER {{ quantity > 1 ? quantity + ' × ' : '' }}{{ fmt(mul(unit, quantity), true) }}</button>
    </template>
  </Modal>
</template>
<style scoped>
.qv { min-width: 44px; text-align: center; font-size: 24px; font-weight: 800; }
.group { margin-bottom: 16px; } .gname { font-weight: 700; margin-bottom: 8px; display: flex; align-items: center; gap: 8px; }
.opts { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 8px; }
.opt { display: flex; flex-direction: column; align-items: flex-start; gap: 2px; min-height: 58px; padding: 8px 12px; border-radius: 12px; border: 2px solid var(--border); background: var(--surface-2); font-weight: 600; text-align: left; }
.opt.on { border-color: var(--success); background: var(--success-soft); } .opt.off { opacity: .4; }

/* --- versions (variante) --- */
.versions { margin-bottom: 14px; padding-bottom: 14px; border-bottom: 1px solid var(--line); }
/*
    Les versions se rangent par TROIS, quoi qu'il arrive - la ou les options se
    repartissent selon la place disponible.

    Un axe de pate se lit en deux rangees qui se repondent : Normale, Cereale, Chia
    au-dessus, et les memes en double au-dessous, chacune sous la sienne. Laisser la
    grille remplir la largeur mettait quatre versions sur la premiere rangee et cassait
    cette lecture : le doigt cherchait la double de la chia sous la cereale.

    Sur un ecran etroit, deux colonnes plutot que trois - trois pastilles de 105 px
    deviennent illisibles avant de devenir pratiques.
*/
.versions .opts { grid-template-columns: repeat(3, minmax(0, 1fr)); }
@media (max-width: 560px) { .versions .opts { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
/* Une version se distingue d'une option : elle decide du prix, elle n'ajoute rien. */
.versions .opt.version { border-color: var(--line-2); }
.versions .opt.version.on { border-color: var(--brand); background: var(--brand-soft); }
/*
    La photo de la version, quand elle en a une.

    En bandeau au-dessus du nom, et non en vignette a cote : les trois versions se lisent
    alors d'un coup d'oeil, comme trois cartes, ce qui est justement l'interet d'avoir mis
    une photo. Une version sans photo garde son bouton d'avant - la rangee reste lisible
    meme si le gerant n'en a photographie qu'une.
*/
.versions .opt .vue {
  width: 100%; height: 62px; object-fit: cover; display: block;
  border-radius: 8px; margin-bottom: 4px; background: var(--surface-3);
}
/* Grisee et non masquee : le gerant voit qu'il lui reste a la tarifer. */
.versions .opt.sansprix { opacity: .45; cursor: not-allowed; }
/* Une version epuisee reste VISIBLE : elle disparaitrait qu'on la chercherait. */
.versions .opt.epuisee { opacity: .5; cursor: not-allowed; border-color: var(--danger-line); background: var(--danger-soft); }
.restant { margin: 9px 0 0; font-size: 13.5px; color: var(--ink-3); }
.restant.trop { color: var(--danger); font-weight: 650; }
.qv.trop { color: var(--danger); }
.versions .opt.epuisee .epuise { font-size: 12px; font-weight: 700; letter-spacing: .06em; text-transform: uppercase; color: var(--danger); }
.delta { font-size: 13px; color: var(--accent-2); font-weight: 700; }
.sub { border: 2px dashed var(--border); border-radius: 12px; padding: 12px; }

/* Options repetables : le compteur et le retrait s'ajoutent sans deplacer le
   libelle, pour que la tuile garde la meme silhouette selectionnee ou non. */
.opt { position: relative; }
.mult {
  position: absolute; top: 6px; right: 8px;
  font-size: 13px; font-weight: 800; color: #fff; background: var(--success);
  border-radius: 999px; padding: 1px 7px; letter-spacing: -.01em;
}
.less {
  position: absolute; bottom: 5px; right: 6px;
  width: 26px; height: 26px; display: grid; place-items: center;
  font-size: 17px; font-weight: 700; line-height: 1; color: var(--text-muted, #857B70);
  border: 1px solid var(--border); border-radius: 8px; background: #fff;
}
.less:hover { border-color: var(--success); color: var(--success); }
.oname { padding-right: 34px; }
</style>
