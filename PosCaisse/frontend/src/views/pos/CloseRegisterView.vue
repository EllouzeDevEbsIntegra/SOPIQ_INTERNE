<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../../api'
import { useAuthStore } from '../../stores/auth'
import { useUiStore } from '../../stores/ui'
import { add, fmt, parseAmount, sub } from '../../utils/money'
import { fmtDateTime } from '../../utils/dates'
import NumPad from '../../components/common/NumPad.vue'
import Icon from '../../components/common/Icon.vue'
import Modal from '../../components/common/Modal.vue'
import ReceiptPaper from '../../components/pos/ReceiptPaper.vue'
import { useCatalogStore } from '../../stores/catalog'
import { printJobs } from '../../composables/usePrinter'
const router = useRouter(); const auth = useAuthStore(); const ui = useUiStore(); const catalog = useCatalogStore()
const summary = ref(null); const counted = ref(''); const note = ref(''); const busy = ref(false); const result = ref(null)
// L'etat de caisse : rendu par le serveur, montre avant d'etre imprime. La session garde
// son identifiant apres la cloture, le temps d'imprimer l'etat definitif.
const sessionId = ref(null); const etat = ref(null); const template = ref(null)
onMounted(async () => {
  sessionId.value = auth.session?.id || null
  try { summary.value = await api.pos.summary(auth.session.id) } catch (e) { ui.error(e.humanMessage) }
  api.admin.activeTemplate().then(t => { template.value = { ...t, logoData: catalog.company?.logoData } }).catch(() => {})
})
/* Les moyens de paiement hors especes, et leur total : c'est ce qui a ete encaisse
   ailleurs que dans le tiroir. */
const autresMoyens = computed(() => (summary.value?.byMethod || []).filter(m => m.kind !== 'CASH'))
const horsEspeces = computed(() => add(summary.value?.cardSales || 0, summary.value?.otherSales || 0))

/** Un taux se lit comme il a ete saisi : 25, et non 25,000. */
const pct = (v) => String(Number(v)).replace('.', ',')
async function voirEtat() {
  if (!sessionId.value) return
  try { etat.value = await api.pos.report(sessionId.value) } catch (e) { ui.error(e.humanMessage) }
}
async function imprimerEtat() {
  if (!etat.value) return
  await printJobs([{ title: etat.value.title, content: etat.value.content, copies: 1 }], template.value)
}
const diff = () => sub(parseAmount(counted.value), summary.value?.expectedCash || 0)
/*
    Rien de compté : la caisse se clôture sur le théorique, sans écart.

    Le caissier qui n'a pas recompté son tiroir ne veut pas déclarer zéro dinar - il
    veut dire << c'est bon >>. Saisir zéro enregistrait pourtant un manquant égal à
    tout le fond de caisse, et le bouton, lui, restait éteint : la clôture ne partait
    pas et rien ne disait pourquoi. On reprend donc le théorique, et la confirmation
    le dit en toutes lettres, pour que ce ne soit jamais un choix fait à sa place.
*/
const sansSaisie = () => parseAmount(counted.value) <= 0
async function close() {
  if (busy.value || !summary.value) return
  const vide = sansSaisie()
  const c = vide ? Number(summary.value.expectedCash) : parseAmount(counted.value)
  const d = vide ? 0 : diff()
  const message = vide
    ? `Aucune somme comptée n'a été saisie.\n\nLa caisse sera clôturée sur les espèces théoriques : ${fmt(c, true)}\nÉcart : ${fmt(0, true)}\n\nConfirmer la clôture ?`
    : `Espèces théoriques : ${fmt(summary.value.expectedCash, true)}\nEspèces comptées : ${fmt(c, true)}\nÉcart : ${d >= 0 ? '+' : ''}${fmt(d, true)}\n\nConfirmer la clôture ?`
  if (!await ui.confirm({ title: 'Clôturer la caisse', message, okLabel: 'Clôturer' })) return
  busy.value = true
  try { result.value = await api.pos.close(auth.session.id, { countedCash: c, note: note.value || null }); sessionId.value = result.value.id; etat.value = null; auth.setSession(null); ui.success('Caisse clôturée') }
  catch (e) { ui.error(e.humanMessage) } finally { busy.value = false }
}
function finish() { auth.logout(); router.replace('/login') }
</script>
<template>
  <div class="close-page">
    <div class="close-card">
      <header class="head"><div><span class="eyebrow">Fin de service</span><h1>Clôture de caisse</h1><div class="muted small">{{ auth.session?.registerName || result?.registerName }} · {{ auth.user?.fullName }}</div></div><div class="row gap-8"><button class="btn" :disabled="!sessionId" @click="voirEtat"><Icon name="printer" :size="17" />État de caisse</button><router-link v-if="!result" class="btn" to="/pos"><Icon name="arrowLeft" :size="17" />Retour au POS</router-link></div></header>
      <div v-if="result" class="result">
        <h2 class="ok"><Icon name="check" :size="20" :stroke="2.6" />Session clôturée</h2>
        <div class="grid-kpi mt-16">
          <div class="kpi"><span class="label">Théorique</span><span class="value num">{{ fmt(result.expectedCash, true) }}</span></div>
          <div class="kpi"><span class="label">Réel compté</span><span class="value num">{{ fmt(result.countedCash, true) }}</span></div>
          <div class="kpi" :style="{ background: Number(result.cashDifference)===0 ? 'var(--success-soft)' : 'var(--danger-soft)' }"><span class="label">Écart</span><span class="value num">{{ Number(result.cashDifference) >= 0 ? '+' : '' }}{{ fmt(result.cashDifference, true) }}</span></div>
          <div class="kpi"><span class="label">Tickets</span><span class="value num">{{ result.ticketsCount }}</span><span class="sub">CA {{ fmt(result.revenue, true) }}</span></div>
        </div>
        <div class="muted small mt-16">Ouverte {{ fmtDateTime(result.openedAt) }} · clôturée {{ fmtDateTime(result.closedAt) }}</div>
        <div class="row mt-16 gap-8"><button class="btn xl primary grow" @click="finish">Terminer et se déconnecter</button><router-link class="btn xl" to="/open">Rouvrir une caisse</router-link></div>
      </div>
      <div v-else-if="summary" class="grid">
        <div class="col gap-8">
          <div class="card-title">Récapitulatif de la session</div>
          <div class="lines">
            <div class="l"><span>Fond initial</span><b class="num">{{ fmt(summary.openingFloat) }}</b></div>
            <div class="l"><span>+ Ventes espèces</span><b class="num">{{ fmt(summary.cashSales) }}</b></div>
            <div class="l"><span>− Remboursements espèces</span><b class="num">{{ fmt(summary.cashRefunds) }}</b></div>
            <div class="l"><span>+ Entrées de caisse</span><b class="num">{{ fmt(summary.cashIn) }}</b></div>
            <div class="l"><span>− Sorties de caisse</span><b class="num">{{ fmt(summary.cashOut) }}</b></div>
            <div class="l total"><span>ESPÈCES THÉORIQUES</span><b class="num">{{ fmt(summary.expectedCash, true) }}</b></div>
          </div>
          <div class="lines mt-8">
            <!-- Tout ce qui n'est pas des espèces, sous un seul titre : les espèces sont
                 déjà comptées au-dessus, avec le fond de caisse et les mouvements. -->
            <div class="l"><span>AUTRES PAIEMENTS</span><b class="num">{{ fmt(horsEspeces) }}</b></div>
            <div class="l" v-for="m in autresMoyens" :key="m.name"><span class="muted small">· {{ m.name }}</span><span class="num small">{{ fmt(m.amount) }}</span></div>
            <div class="l"><span>Tickets / annulations</span><b class="num">{{ summary.ticketsCount }} / {{ summary.cancellationsCount }}</b></div>
            <div class="l"><span>Remises accordées</span><b class="num">{{ fmt(summary.discounts) }}</b></div>
            <div class="l total"><span>CHIFFRE D'AFFAIRES</span><b class="num">{{ fmt(summary.revenue, true) }}</b></div>
          </div>
          <!-- Le benefice n'apparait que si un taux a ete pose au back-office : un
               << 0,000 DT >> se lirait comme une journee sans marge, ce qui n'est pas ce
               que dit un reglage vide. -->
          <div v-if="Number(summary.marginPercent) > 0" class="lines benef mt-8">
            <div class="l total"><span>BÉNÉFICE ESTIMÉ</span><b class="num">{{ fmt(summary.estimatedProfit, true) }}</b></div>
            <div class="l"><span class="muted small">{{ pct(summary.marginPercent) }} % du chiffre d'affaires</span></div>
          </div>
        </div>
        <div class="col gap-8">
          <div class="card-title">Espèces réellement comptées</div>
          <NumPad v-model="counted" mode="amount" ok-label="Clôturer" @ok="close" />
          <div class="ecart" :class="{ ok: !sansSaisie() && diff()===0, bad: !sansSaisie() && diff()!==0 }"><span>Théorique {{ fmt(summary.expectedCash) }} · réel {{ sansSaisie() ? '—' : fmt(parseAmount(counted)) }}</span><b class="num">{{ !sansSaisie() ? (diff() >= 0 ? 'Écart +' : 'Écart ') + fmt(diff(), true) : 'Sans saisie : clôture sur le théorique, sans écart' }}</b></div>
          <div class="field"><label>Commentaire</label><input class="input" v-model="note" placeholder="ex. écart dû à…" /></div>
          <button class="btn danger solid xl block" :disabled="busy" @click="close"><Icon name="lock" :size="18" />Clôturer la caisse</button>
        </div>
      </div>
      <div v-else class="spinner"></div>
    </div>
    <Modal v-if="etat" size="md" :title="etat.title" @close="etat = null">
      <div class="apercu scroll"><ReceiptPaper :content="etat.content" :paper-width="template?.paperWidth || 80" :font-size="template?.fontSize || 12"
                                               :logo="template?.showLogo ? template?.logoData : null" /></div>
      <template #foot>
        <button class="btn lg" @click="etat = null">Fermer</button>
        <button class="btn lg primary" @click="imprimerEtat"><Icon name="printer" :size="17" />Imprimer</button>
      </template>
    </Modal>
  </div>
</template>
<style scoped>
.close-page { min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 16px; overflow: auto; }
.close-card { background: var(--surface); border: 1px solid var(--line); border-radius: var(--r-xl); padding: 26px 28px; width: min(100%, 1020px); box-shadow: var(--shadow-2); }
h1 { font-size: 25px; margin-top: 2px; }
.head { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; margin-bottom: 20px; }
.ok { display: flex; align-items: center; gap: 9px; color: var(--pay-2); font-size: 21px; } .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 26px; }
.lines { background: var(--surface-2); border: 1px solid var(--line); border-radius: var(--r); padding: 6px 14px; } .l { display: flex; justify-content: space-between; gap: 12px; padding: 6px 0; font-size: 14px; color: var(--ink-2); border-bottom: 1px solid var(--line); }
.l:last-child { border-bottom: 0; }
.l.total { border-bottom: 0; font-size: 16px; font-weight: 650; color: var(--ink); padding-top: 9px; }
.l.total b { font-family: var(--font-display); font-size: 19px; }
.ecart { display: flex; flex-direction: column; gap: 3px; padding: 13px 15px; border-radius: var(--r); font-weight: 650; background: var(--surface-2); border: 1px solid var(--line); }
.ecart b { font-family: var(--font-display); font-size: 25px; letter-spacing: -.02em; }
.ecart:not(.ok):not(.bad) b { font-size: 15px; font-weight: 600; color: var(--ink-3); }
.ecart.ok { background: var(--pay-soft); border-color: var(--pay-line); color: var(--pay-2); }
.ecart.bad { background: var(--warn-soft); border-color: var(--warn-line); color: var(--warn); }
.benef .total b { color: var(--pay-2); }
.apercu { background: #e2e8f0; padding: 16px; border-radius: 12px; max-height: 60vh; }
@media (max-width: 760px) { .grid { grid-template-columns: 1fr; } }
</style>
