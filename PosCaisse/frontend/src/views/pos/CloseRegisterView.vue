<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../../api'
import { useAuthStore } from '../../stores/auth'
import { useUiStore } from '../../stores/ui'
import { fmt, parseAmount, sub } from '../../utils/money'
import { fmtDateTime } from '../../utils/dates'
import NumPad from '../../components/common/NumPad.vue'
const router = useRouter(); const auth = useAuthStore(); const ui = useUiStore()
const summary = ref(null); const counted = ref(''); const note = ref(''); const busy = ref(false); const result = ref(null)
onMounted(async () => { try { summary.value = await api.pos.summary(auth.session.id) } catch (e) { ui.error(e.humanMessage) } })
const diff = () => sub(parseAmount(counted.value), summary.value?.expectedCash || 0)
async function close() {
  if (busy.value || !summary.value) return
  const c = parseAmount(counted.value)
  const d = diff()
  if (!await ui.confirm({ title: 'Clôturer la caisse', message: `Espèces théoriques : ${fmt(summary.value.expectedCash, true)}\nEspèces comptées : ${fmt(c, true)}\nÉcart : ${d >= 0 ? '+' : ''}${fmt(d, true)}\n\nConfirmer la clôture ?`, okLabel: 'Clôturer' })) return
  busy.value = true
  try { result.value = await api.pos.close(auth.session.id, { countedCash: c, note: note.value || null }); auth.setSession(null); ui.success('Caisse clôturée') }
  catch (e) { ui.error(e.humanMessage) } finally { busy.value = false }
}
function finish() { auth.logout(); router.replace('/login') }
</script>
<template>
  <div class="close-page">
    <div class="close-card">
      <div class="row between mb-16"><div><h1>Clôture de caisse</h1><div class="muted">{{ auth.session?.registerName || result?.registerName }} · {{ auth.user.fullName }}</div></div><router-link v-if="!result" class="btn" to="/pos">← Retour au POS</router-link></div>
      <div v-if="result" class="result">
        <h2>✅ Session clôturée</h2>
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
            <div class="l"><span>Carte bancaire</span><b class="num">{{ fmt(summary.cardSales) }}</b></div>
            <div class="l"><span>Autres paiements</span><b class="num">{{ fmt(summary.otherSales) }}</b></div>
            <div class="l" v-for="(v,k) in summary.byMethod" :key="k"><span class="muted small">· {{ k }}</span><span class="num small">{{ fmt(v) }}</span></div>
            <div class="l"><span>Tickets / annulations</span><b class="num">{{ summary.ticketsCount }} / {{ summary.cancellationsCount }}</b></div>
            <div class="l"><span>Remises accordées</span><b class="num">{{ fmt(summary.discounts) }}</b></div>
            <div class="l total"><span>CHIFFRE D'AFFAIRES</span><b class="num">{{ fmt(summary.revenue, true) }}</b></div>
          </div>
        </div>
        <div class="col gap-8">
          <div class="card-title">Espèces réellement comptées</div>
          <NumPad v-model="counted" mode="amount" ok-label="CLÔTURER" @ok="close" />
          <div class="ecart" :class="{ ok: diff()===0, bad: diff()!==0 }"><span>THÉORIQUE {{ fmt(summary.expectedCash) }} · RÉEL {{ fmt(parseAmount(counted)) }}</span><b class="num">ÉCART {{ diff() >= 0 ? '+' : '' }}{{ fmt(diff(), true) }}</b></div>
          <div class="field"><label>Commentaire</label><input class="input" v-model="note" placeholder="ex. écart dû à…" /></div>
          <button class="btn danger solid xl block" :disabled="busy || !counted" @click="close">CLÔTURER LA CAISSE</button>
        </div>
      </div>
      <div v-else class="spinner"></div>
    </div>
  </div>
</template>
<style scoped>
.close-page { min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 16px; overflow: auto; }
.close-card { background: var(--surface); border-radius: 22px; padding: 26px; width: min(100%, 1000px); box-shadow: var(--shadow-lg); }
h1 { font-size: 26px; } .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 26px; }
.lines { background: var(--surface-2); border-radius: 12px; padding: 8px 12px; } .l { display: flex; justify-content: space-between; padding: 5px 0; border-bottom: 1px dashed var(--border); }
.l.total { border: 0; font-size: 18px; padding-top: 8px; }
.ecart { display: flex; flex-direction: column; gap: 2px; padding: 12px 14px; border-radius: 12px; font-weight: 700; background: var(--surface-2); }
.ecart b { font-size: 24px; } .ecart.ok { background: var(--success-soft); color: var(--success-2); } .ecart.bad { background: var(--warning-soft); color: #b45309; }
@media (max-width: 760px) { .grid { grid-template-columns: 1fr; } }
</style>
