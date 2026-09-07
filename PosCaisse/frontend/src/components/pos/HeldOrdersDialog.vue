<script setup>
/**
 * Les commandes en attente, et ce que le stock permet encore d'en servir.
 *
 * Une commande peut attendre une heure. Pendant ce temps, d'autres clients passent et
 * la pâte descend : ce qui etait servable a midi ne l'est plus a midi et quart. Le
 * contrôle tombe donc AU MOMENT DE REPRENDRE, avant que la commande n'entre au panier -
 * et non a l'encaissement, ou le caissier a deja tout recompose devant le client.
 *
 * Quand il manque de quoi tout servir, on ne refuse pas sechement : on montre ce qui
 * reste possible ligne par ligne, et on laisse le caissier trancher - reprendre au
 * reduit, ou supprimer la commande. C'est lui qui a le client en face.
 */
import { computed, onMounted, ref } from 'vue'
import Modal from '../common/Modal.vue'
import Icon from '../common/Icon.vue'
import { api } from '../../api'
import { useAuthStore } from '../../stores/auth'
import { useCatalogStore } from '../../stores/catalog'
import { useUiStore } from '../../stores/ui'
import { fmt, fmtQty } from '../../utils/money'
import { fmtTime } from '../../utils/dates'
import { porteurEtPas, valeursParId } from '../../utils/stock'
const props = defineProps({ stock: { type: Object, default: () => ({}) } })
const emit = defineEmits(['close', 'resume'])
const auth = useAuthStore(); const ui = useUiStore(); const catalog = useCatalogStore()
const orders = ref([]); const loading = ref(true)
async function load() { loading.value = true; try { orders.value = await api.pos.held(auth.session?.pointOfSaleId) } catch (e) { ui.error(e.humanMessage) } finally { loading.value = false } }
onMounted(load)
const plan = ref(null)   // ce que le stock permet, quand il ne permet pas tout

/**
 * Ce que chaque ligne peut encore donner, dans l'ordre de la commande.
 *
 * Les lignes se servent l'une apres l'autre sur le meme stock : la premiere prend ce
 * qu'il lui faut, la suivante prend ce qui reste. C'est ce que ferait la cuisine, et
 * cela evite de promettre deux fois la meme pate a deux lignes du meme ticket.
 *
 * Une ligne qui ne consomme aucune pate suivie passe entiere : le stock ne la concerne
 * pas.
 */
function planifier(o) {
  const valeurs = valeursParId(catalog)
  const reste = { ...props.stock }
  const lignes = []
  let reduit = false
  for (const ol of o.lines) {
    const demande = Number(ol.quantity) || 0
    // Ce qu'UNE unite de cette ligne retire, compteur par compteur - la ligne elle-meme,
    // et les composants d'un menu, qui prennent la version par defaut de leur article.
    const parUnite = {}
    const ajouter = (valeurId, qte) => {
      const pp = porteurEtPas(valeurs[valeurId])
      if (pp && qte > 0) parUnite[pp.porteur] = (parUnite[pp.porteur] || 0) + pp.pas * qte
    }
    ajouter(ol.variantValueId, 1)
    for (const c of ol.components || []) {
      const p = catalog.productsById?.[c.productId]
      if (p?.defaultVariantValueId) ajouter(p.defaultVariantValueId, Number(c.quantity) || 0)
    }
    let possible = demande
    for (const [porteur, besoin] of Object.entries(parUnite)) {
      const dispo = reste[porteur]
      if (dispo === undefined || dispo === null) continue      // pate non suivie
      possible = Math.min(possible, Math.floor((Number(dispo) + 1e-9) / besoin))
    }
    possible = Math.max(0, possible)
    for (const [porteur, besoin] of Object.entries(parUnite)) {
      if (reste[porteur] !== undefined) reste[porteur] = Number(reste[porteur]) - besoin * possible
    }
    if (possible < demande) reduit = true
    lignes.push({ ol, demande, possible,
                  nom: ol.productName + (ol.variantValueName ? ' ' + ol.variantValueName : '') })
  }
  return { order: o, lignes, reduit }
}

function reprendre(o) {
  const p = planifier(o)
  if (!p.reduit) return emit('resume', o)
  plan.value = p
}
const rienAServir = computed(() => plan.value && !plan.value.lignes.some(l => l.possible > 0))

/** Reprendre au reduit : les lignes tombees a zero ne partent pas au panier. */
function reprendreReduit() {
  const o = plan.value.order
  const lines = plan.value.lignes.filter(l => l.possible > 0)
                                .map(l => ({ ...l.ol, quantity: l.possible }))
  plan.value = null
  emit('resume', { ...o, lines })
}

async function supprimerDepuisPlan() {
  const o = plan.value.order
  try { await api.pos.abandon(o.id); plan.value = null; ui.success('Commande supprimée'); load() }
  catch (e) { ui.error(e.humanMessage) }
}

async function abandon(o) {
  if (!await ui.confirm({ title: 'Abandonner la commande', message: `Abandonner ${o.heldRef} (${fmt(o.total, true)}) ?`, okLabel: 'Abandonner', danger: true })) return
  try { await api.pos.abandon(o.id); ui.success('Commande abandonnée'); load() } catch (e) { ui.error(e.humanMessage) }
}
</script>
<template>
  <Modal size="md" title="Commandes en attente" @close="emit('close')">
    <div v-if="loading" class="spinner"></div>
    <div v-else-if="!orders.length" class="empty">Aucune commande en attente</div>
    <div v-else class="list">
      <div v-for="o in orders" :key="o.id" class="held">
        <div class="grow">
          <div class="row gap-8"><b style="font-size:18px">{{ o.heldRef }}</b><span class="badge">{{ fmtTime(o.createdAt) }}</span><span class="badge info">{{ o.cashierName }}</span><span v-if="o.customerName" class="badge accent"><Icon name="user" :size="13" />{{ o.customerName }}</span></div>
          <div class="muted small">{{ o.lines.map(l => Number(l.quantity) + '× ' + l.productName).join(', ') }}</div>
        </div>
        <b class="num" style="font-size:20px">{{ fmt(o.total, true) }}</b>
        <button class="btn danger" @click="abandon(o)" v-if="auth.can('ORDER_CANCEL')"><Icon name="trash" :size="16" /></button>
        <button class="btn success lg" @click="reprendre(o)">REPRENDRE</button>
      </div>
    </div>
  </Modal>

  <!-- Stock insuffisant : on montre ce qui reste possible, et le caissier tranche. -->
  <Modal v-if="plan" size="md" :title="'Stock insuffisant — ' + plan.order.heldRef" @close="plan = null">
    <div class="col gap-12">
      <p class="dit">
        Cette commande attend depuis {{ fmtTime(plan.order.createdAt) }}, et la pâte a servi entre-temps.
        Voici ce qu'il reste de quoi préparer :
      </p>
      <div class="plan">
        <div v-for="(l, i) in plan.lignes" :key="i" class="pl" :class="{ reduit: l.possible < l.demande, nul: !l.possible }">
          <span class="n">{{ l.nom }}</span>
          <span class="d num">{{ fmtQty(l.demande) }} demandé{{ l.demande > 1 ? 's' : '' }}</span>
          <span class="fl">→</span>
          <b class="p num">{{ l.possible ? fmtQty(l.possible) + ' possible' + (l.possible > 1 ? 's' : '') : 'retirée' }}</b>
        </div>
      </div>
      <p v-if="rienAServir" class="dit alerte">
        Aucune ligne ne peut être servie avec le stock actuel. Entrez des pâtes depuis le bouton
        <b>Stock</b>, ou supprimez cette commande.
      </p>
    </div>
    <template #foot>
      <button class="btn lg" @click="plan = null">Annuler</button>
      <button class="btn lg danger" @click="supprimerDepuisPlan"><Icon name="trash" :size="16" />Supprimer cette commande en attente</button>
      <button class="btn lg success" :disabled="rienAServir" @click="reprendreReduit">Récupérer avec ces valeurs</button>
    </template>
  </Modal>
</template>
<style scoped>
.list { display: flex; flex-direction: column; gap: 8px; }
.dit { font-size: 14.5px; line-height: 1.55; color: var(--ink-2); margin: 0; }
.dit.alerte { color: var(--danger); font-weight: 600; }
.plan { border: 1px solid var(--line); border-radius: var(--r); background: var(--surface-2); padding: 4px 12px; }
.pl { display: grid; grid-template-columns: 1fr auto 24px auto; gap: 10px; align-items: baseline;
      padding: 8px 0; border-bottom: 1px solid var(--line); font-size: 14.5px; }
.pl:last-child { border-bottom: 0; }
.pl .n { font-weight: 600; }
.pl .d, .pl .fl { color: var(--ink-3); }
.pl.reduit .p { color: var(--warn); }
.pl.nul .p { color: var(--danger); }
.pl:not(.reduit) .p { color: var(--success); }
.held { display: flex; align-items: center; gap: 12px; padding: 12px; border-radius: 12px; background: var(--surface-2); border: 1px solid var(--border); }
</style>
