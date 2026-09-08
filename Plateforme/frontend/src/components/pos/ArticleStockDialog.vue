<script setup>
/**
 * Le stock d'une boutique, tenu depuis la caisse.
 *
 * Ce qui s'épuise ici n'est pas une pâte mais un ARTICLE : la bouteille, le paquet, la
 * recharge. Il y en a deux cents, pas quatre — l'écran est donc bâti sur la recherche et
 * sur le scan, jamais sur le défilement. On cherche l'article, on tape un chiffre, on
 * choisit ce que ce chiffre veut dire.
 *
 * TROIS GESTES, ET LEUR SENS EST DIFFÉRENT.
 *   — Entrée : la marchandise arrive. Le fournisseur et le prix payé sont gardés, parce
 *     que c'est de là que vient la marge réelle.
 *   — Casse : elle part sans être vendue. Le motif compte : un stock qui descend sans
 *     vente est exactement ce qu'on cherchera à comprendre le soir.
 *   — Inventaire : on POSE le chiffre compté, l'écart se déduit. Faire saisir l'écart
 *     obligerait le gérant à une soustraction devant son rayon, et c'est là que les
 *     erreurs entrent.
 */
import { computed, nextTick, onMounted, ref } from 'vue'
import Modal from '../common/Modal.vue'
import Icon from '../common/Icon.vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useCatalogStore } from '../../stores/catalog'
import { fmt, fmtQty } from '../../utils/money'
import { fmtTime } from '../../utils/dates'

const emit = defineEmits(['close', 'changed'])
const ui = useUiStore()
const catalog = useCatalogStore()

const etat = ref(null)
const busy = ref(false)
const recherche = ref('')
const choisi = ref(null)        // la ligne sur laquelle on agit
const quantite = ref('')
const geste = ref('entree')     // entree | casse | inventaire
const fournisseur = ref('')
const prixAchat = ref('')
const motif = ref('')
const detail = ref(false)

async function charger(x) {
  try { etat.value = x || await api.pos.articleStock() } catch (e) { ui.error(e.humanMessage || e) }
}
onMounted(async () => { await charger(); await nextTick(); document.getElementById('rech-stock')?.focus() })

const lignes = computed(() => etat.value?.lines || [])
const alerte = computed(() => lignes.value.filter(l => l.sousLeSeuil))

/*
    La liste ne montre pas tout : deux cents lignes ne se lisent pas. Sans recherche, on
    affiche ce qui manque - c'est la question du matin. Dès qu'on tape, on cherche
    partout, nom et code-barres compris : le scan tombe donc juste sur l'article.
*/
const filtrees = computed(() => {
  const q = recherche.value.trim().toLowerCase()
  if (!q) return alerte.value.slice(0, 60)
  return lignes.value.filter(l =>
    l.name.toLowerCase().includes(q) || (l.barcode || '').includes(q) ||
    (l.code || '').toLowerCase().includes(q) || (l.categoryName || '').toLowerCase().includes(q)
  ).slice(0, 60)
})

/** Entrée dans la recherche : un code-barres exact désigne l'article, sans le chercher. */
function rechercheEntree() {
  const q = recherche.value.trim()
  const exact = lignes.value.find(l => l.barcode && l.barcode === q)
  if (exact) { prendre(exact); recherche.value = '' }
  else if (filtrees.value.length === 1) prendre(filtrees.value[0])
}

function prendre(l) {
  choisi.value = l
  quantite.value = ''
  motif.value = ''
  prixAchat.value = l.purchasePrice > 0 ? String(l.purchasePrice) : ''
}

function tape(k) {
  const v = String(quantite.value || '')
  quantite.value = k === 'C' ? '' : k === '<' ? v.slice(0, -1) : (v + k).slice(0, 6)
}
const saisi = computed(() => Number(quantite.value || 0))

const titreGeste = computed(() => geste.value === 'entree' ? 'Entrée de stock'
  : geste.value === 'casse' ? 'Casse / perte' : 'Inventaire')

/** Ce que le chiffre tapé va donner, dit avant de valider — on ne signe pas à l'aveugle. */
const apres = computed(() => {
  if (!choisi.value || !quantite.value) return null
  const q = Number(choisi.value.quantity)
  if (geste.value === 'entree') return q + saisi.value
  if (geste.value === 'casse') return q - saisi.value
  return saisi.value
})

async function valider() {
  if (!choisi.value) return ui.error('Choisissez un article.')
  if (geste.value !== 'inventaire' && !(saisi.value > 0)) return ui.error('Saisissez une quantité.')
  if (geste.value === 'inventaire' && quantite.value === '') return ui.error('Saisissez la quantité comptée.')
  busy.value = true
  try {
    const corps = { productId: choisi.value.productId, quantity: saisi.value }
    let r
    if (geste.value === 'entree') {
      if (prixAchat.value) corps.unitCost = Number(String(prixAchat.value).replace(',', '.'))
      if (fournisseur.value.trim()) corps.supplier = fournisseur.value.trim()
      r = await api.pos.articleStockEntry(corps)
    } else if (geste.value === 'casse') {
      corps.comment = motif.value.trim()
      r = await api.pos.articleStockWaste(corps)
    } else {
      corps.comment = motif.value.trim()
      r = await api.pos.articleStockCount(corps)
    }
    await charger(r)
    const nom = choisi.value.name
    choisi.value = lignes.value.find(l => l.productId === corps.productId) || null
    quantite.value = ''
    ui.success(titreGeste.value + ' — ' + nom)
    emit('changed')
  } catch (e) { ui.error(e.humanMessage || e) } finally { busy.value = false }
}

const LIBELLE = { ENTREE: 'Entrée', VENTE: 'Vente', CASSE: 'Casse', ANNULATION: 'Annulation',
                  REMISE_A_ZERO: 'Remise à zéro', INVENTAIRE: 'Inventaire' }
</script>

<template>
  <Modal size="full" @close="emit('close')">
    <template #head>
      <h2>Stock de la boutique</h2>
      <span v-if="etat" class="pill">{{ lignes.length }} articles suivis</span>
      <span v-if="alerte.length" class="pill danger">{{ alerte.length }} sous le seuil</span>
    </template>

    <div class="stock">
      <!-- ---------------------------------------------------------- chercher -->
      <section class="liste">
        <label class="rech">
          <Icon name="search" :size="17" />
          <input id="rech-stock" v-model="recherche" @keyup.enter="rechercheEntree"
                 placeholder="Scannez l'article, ou tapez son nom…" />
          <button v-if="recherche" class="x" @click="recherche = ''" aria-label="Effacer">
            <Icon name="close" :size="14" /></button>
        </label>
        <p class="quoi small muted">
          {{ recherche ? filtrees.length + ' résultat(s)' :
             alerte.length ? 'Ce qui est sous le seuil — à recommander' : 'Tout est au-dessus du seuil : cherchez un article.' }}
        </p>

        <div class="rows scroll">
          <button v-for="l in filtrees" :key="l.productId" class="row" :class="{ on: choisi?.productId === l.productId }"
                  @click="prendre(l)">
            <span class="n">
              <b>{{ l.name }}</b>
              <em>{{ l.categoryName }}<template v-if="l.barcode"> · {{ l.barcode }}</template></em>
            </span>
            <span class="q num" :class="{ bas: l.sousLeSeuil }">{{ fmtQty(l.quantity) }}</span>
          </button>
          <p v-if="!filtrees.length" class="vide">Aucun article ne correspond.</p>
        </div>
      </section>

      <!-- ---------------------------------------------------------- agir -->
      <aside class="agir" v-if="choisi">
        <div class="tete">
          <b>{{ choisi.name }}</b>
          <span class="small muted">{{ choisi.categoryName }}<template v-if="choisi.barcode"> · {{ choisi.barcode }}</template></span>
          <div class="chiffres">
            <span class="num gros" :class="{ bas: choisi.sousLeSeuil }">{{ fmtQty(choisi.quantity) }}</span>
            <em>en stock<template v-if="Number(choisi.stockMin) > 0"> · seuil {{ fmtQty(choisi.stockMin) }}</template></em>
          </div>
          <div class="tarifs small muted">
            Vente {{ fmt(choisi.price) }}<template v-if="Number(choisi.purchasePrice) > 0"> · achat {{ fmt(choisi.purchasePrice) }}</template>
          </div>
        </div>

        <div class="gestes">
          <button class="g" :class="{ on: geste === 'entree' }" @click="geste = 'entree'">Entrée</button>
          <button class="g" :class="{ on: geste === 'casse' }" @click="geste = 'casse'">Casse</button>
          <button class="g" :class="{ on: geste === 'inventaire' }" @click="geste = 'inventaire'">Inventaire</button>
        </div>

        <div class="ecran num">
          {{ quantite || '0' }}
          <em v-if="apres !== null">→ {{ fmtQty(apres) }}</em>
        </div>
        <div class="pave">
          <button v-for="k in ['1','2','3','4','5','6','7','8','9','C','0','<']" :key="k"
                  class="t" :class="{ fn: k === 'C' || k === '<' }" @click="tape(k)">
            <span v-if="k === '<'">⌫</span><span v-else>{{ k }}</span>
          </button>
        </div>

        <template v-if="geste === 'entree'">
          <div class="ligne-champ">
            <label>Prix d'achat</label>
            <input class="input num" v-model="prixAchat" inputmode="decimal" placeholder="0,000" />
          </div>
          <div class="ligne-champ">
            <label>Fournisseur</label>
            <input class="input" v-model="fournisseur" maxlength="120" placeholder="facultatif" />
          </div>
        </template>
        <div v-else class="ligne-champ">
          <label>{{ geste === 'casse' ? 'Motif' : 'Note' }}</label>
          <input class="input" v-model="motif" maxlength="300"
                 :placeholder="geste === 'casse' ? 'cassé, périmé, volé…' : 'comptage rayon'" />
        </div>

        <button class="btn lg primary valider" :disabled="busy" @click="valider">{{ titreGeste }}</button>
      </aside>

      <aside class="agir vide-agir" v-else>
        <Icon name="box" :size="34" />
        <p>Scannez un article ou touchez-le dans la liste.</p>
      </aside>

      <!-- Les mouvements sous la liste, jamais dans le pied : ils y recouvraient le pavé
           numérique dès qu'on les ouvrait, c'est-à-dire au moment ou on en a besoin. -->
      <section v-if="detail" class="mouvements-bloc">
        <span class="eyebrow">Mouvements du jour</span>
        <div class="mouvements scroll">
          <div v-for="m in (etat?.movements || [])" :key="m.id" class="mv">
            <span class="h">{{ fmtTime(m.createdAt) }}</span>
            <span class="t">{{ LIBELLE[m.type] || m.type }}</span>
            <b class="a">{{ m.productName }}</b>
            <span class="q num" :class="{ moins: Number(m.quantity) < 0 }">{{ Number(m.quantity) > 0 ? '+' : '' }}{{ fmtQty(m.quantity) }}</span>
            <span class="r num">→ {{ fmtQty(m.resulting) }}</span>
            <em>{{ [m.supplier, m.comment, m.userName].filter(Boolean).join(' · ') }}</em>
          </div>
          <p v-if="!(etat?.movements || []).length" class="vide">Aucun mouvement aujourd'hui.</p>
        </div>
      </section>
    </div>

    <template #foot>
      <button class="btn" @click="detail = !detail">{{ detail ? 'Masquer' : 'Voir' }} les mouvements du jour</button>
      <button class="btn lg" @click="emit('close')">Fermer</button>
    </template>
  </Modal>
</template>

<style scoped>
.stock { display: grid; grid-template-columns: 1fr 340px; gap: 16px; min-height: 62vh; }
@media (max-width: 900px) { .stock { grid-template-columns: 1fr; } }

.rech { display: flex; align-items: center; gap: 9px; height: 46px; padding: 0 12px;
        border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface); }
.rech input { flex: 1; min-width: 0; border: 0; outline: none; background: none; font-size: 15px; }
.rech .x { color: var(--ink-3); }
.quoi { margin: 8px 2px; }
.rows { display: grid; gap: 6px; max-height: 52vh; }
.row { display: flex; align-items: center; gap: 12px; padding: 9px 12px; text-align: left;
       border: 1px solid var(--line); border-radius: var(--r-sm); background: var(--surface); }
.row:hover { background: var(--surface-2); }
.row.on { border-color: var(--brand); background: var(--brand-soft); }
.row .n { flex: 1; min-width: 0; display: grid; }
.row .n b { font-size: 14.5px; font-weight: 620; }
.row .n em { font-style: normal; font-size: 11.5px; color: var(--ink-3); }
.row .q { font-size: 18px; font-weight: 750; }
.row .q.bas { color: var(--danger); }
.vide { padding: 18px; text-align: center; color: var(--ink-3); font-size: 13px; }

.agir { display: grid; align-content: start; gap: 11px; padding: 14px;
        border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface-2); }
.vide-agir { align-content: center; justify-items: center; color: var(--ink-4); text-align: center; }
.tete { display: grid; gap: 3px; }
.tete b { font-size: 16px; }
.chiffres { display: flex; align-items: baseline; gap: 8px; margin-top: 4px; }
.gros { font-size: 30px; font-weight: 800; }
.gros.bas { color: var(--danger); }
.chiffres em { font-style: normal; font-size: 12px; color: var(--ink-3); }

.gestes { display: grid; grid-template-columns: repeat(3, 1fr); gap: 6px; }
.g { height: 38px; border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface); font-size: 13.5px; }
.g.on { border-color: var(--brand); background: var(--brand); color: #fff; font-weight: 650; }

.ecran { display: flex; align-items: baseline; justify-content: flex-end; gap: 10px; height: 52px; padding: 0 14px;
         border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface);
         font-size: 26px; font-weight: 750; }
.ecran em { font-style: normal; font-size: 14px; color: var(--ink-3); }
.pave { display: grid; grid-template-columns: repeat(3, 1fr); gap: 6px; }
.pave .t { height: 46px; font-size: 19px; border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface); }
.pave .t.fn { background: var(--surface-3); font-size: 16px; }
.ligne-champ { display: grid; gap: 4px; }
.ligne-champ label { font-size: 11px; letter-spacing: .07em; text-transform: uppercase; color: var(--ink-3); }
.valider { margin-top: 4px; }

.mouvements-bloc { grid-column: 1 / -1; display: grid; gap: 6px; padding-top: 10px; border-top: 1px solid var(--line); }
.mouvements { display: grid; gap: 4px; max-height: 26vh; width: 100%; }
.mv { display: grid; grid-template-columns: 54px 90px 1fr 70px 80px 1fr; gap: 8px; align-items: baseline;
      font-size: 12.5px; padding: 4px 6px; border-bottom: 1px solid var(--line); }
.mv .q.moins { color: var(--danger); }
.mv em { font-style: normal; color: var(--ink-3); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.pill { display: inline-flex; padding: 3px 10px; border-radius: 999px; font-size: 12px;
        background: var(--surface-3); color: var(--ink-2); }
.pill.danger { background: var(--danger-soft, var(--surface-3)); color: var(--danger); font-weight: 650; }
</style>
