<script setup>
import { onMounted, ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../../api'
import { useAuthStore } from '../../stores/auth'
import { useUiStore } from '../../stores/ui'
import { fmt, parseAmount } from '../../utils/money'
import { fmtTime } from '../../utils/dates'
import NumPad from '../../components/common/NumPad.vue'

const router = useRouter(); const auth = useAuthStore(); const ui = useUiStore()
const registers = ref([]); const selected = ref(null); const amount = ref(''); const busy = ref(false)
onMounted(async () => {
  if (auth.session) return router.replace('/pos')
  try { registers.value = await api.pos.registers(auth.user.pointOfSaleId || undefined); const free = registers.value.find(r => !r.openSession); selected.value = free || registers.value[0] || null } catch (e) { ui.error(e.humanMessage) }
})
const canOpen = computed(() => auth.can('REGISTER_OPEN'))
async function open() {
  if (busy.value || !selected.value) return
  if (selected.value.openSession) return ui.error(`Cette caisse possède déjà une session ouverte (par ${selected.value.openSession.openedByName}).`)
  busy.value = true
  try {
    const s = await api.pos.openSession(selected.value.id, parseAmount(amount.value))
    auth.setSession({ id: s.id, registerId: s.registerId, registerCode: s.registerCode, registerName: s.registerName, pointOfSaleId: s.pointOfSaleId, pointOfSaleName: s.pointOfSaleName, openedAt: s.openedAt, openingFloat: s.openingFloat, openedById: s.openedById, openedByName: s.openedByName })
    ui.success(`${s.registerName} ouverte — fond ${fmt(s.openingFloat, true)}`)
    router.replace('/pos')
  } catch (e) { ui.error(e.humanMessage) } finally { busy.value = false }
}
function logout() { auth.logout(); router.replace('/login') }
</script>
<template>
  <div class="open">
    <div class="open-card">
      <div class="row between mb-16">
        <div><h1>Ouverture de caisse</h1><div class="muted">Caissier : <b>{{ auth.user.fullName }}</b></div></div>
        <div class="row">
          <router-link v-if="auth.isBackoffice" class="btn" to="/admin">Back-office</router-link>
          <button class="btn ghost" @click="logout">Déconnexion</button>
        </div>
      </div>
      <div class="grid">
        <div>
          <div class="card-title">Caisse</div>
          <div class="regs">
            <button v-for="r in registers" :key="r.id" class="reg" :class="{ on: selected?.id===r.id, busy: r.openSession }" @click="selected=r">
              <span class="code">{{ r.code }}</span>
              <span class="name">{{ r.name }}</span>
              <span class="pos tiny">{{ r.pointOfSaleName }}</span>
              <span v-if="r.openSession" class="badge warning">Ouverte par {{ r.openSession.openedByName }} à {{ fmtTime(r.openSession.openedAt) }}</span>
              <span v-else class="badge success">Disponible</span>
            </button>
            <p v-if="!registers.length" class="muted">Aucune caisse configurée.</p>
          </div>
        </div>
        <div>
          <div class="card-title">Fond de caisse initial</div>
          <NumPad v-model="amount" mode="amount" ok-label="OUVRIR" placeholder="0" @ok="open" />
          <p v-if="!canOpen" class="muted small mt-8">Vous n'avez pas la permission d'ouvrir une caisse.</p>
          <button class="btn success xl block mt-16" :disabled="busy || !selected || !canOpen || !!selected?.openSession" @click="open">OUVRIR {{ selected?.name || '' }} — {{ fmt(parseAmount(amount), true) }}</button>
        </div>
      </div>
    </div>
  </div>
</template>
<style scoped>
.open { min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 16px; overflow: auto; }
.open-card { background: var(--surface); border-radius: 22px; padding: 26px; width: min(100%, 900px); box-shadow: var(--shadow-lg); }
h1 { font-size: 26px; }
.grid { display: grid; grid-template-columns: 1fr 1fr; gap: 26px; }
.regs { display: flex; flex-direction: column; gap: 10px; }
.reg { display: flex; flex-direction: column; align-items: flex-start; gap: 4px; padding: 14px 16px; border-radius: 14px; border: 2px solid var(--border); background: var(--surface-2); text-align: left; min-height: 90px; }
.reg.on { border-color: var(--accent); background: var(--accent-soft); }
.reg .code { font-size: 12px; font-weight: 700; color: var(--text-3); letter-spacing: .1em; } .reg .name { font-size: 20px; font-weight: 800; }
@media (max-width: 760px) { .grid { grid-template-columns: 1fr; } }
</style>
