<script setup>
import { onMounted, ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../../api'
import { useAuthStore } from '../../stores/auth'
import { useUiStore } from '../../stores/ui'
import { fmt, parseAmount } from '../../utils/money'
import { fmtTime } from '../../utils/dates'
import NumPad from '../../components/common/NumPad.vue'
import Icon from '../../components/common/Icon.vue'

const router = useRouter(); const auth = useAuthStore(); const ui = useUiStore()
const registers = ref([]); const selected = ref(null); const amount = ref(''); const busy = ref(false)

onMounted(async () => {
  if (auth.session) return router.replace('/pos')
  try {
    registers.value = await api.pos.registers(auth.user.pointOfSaleId || undefined)
    selected.value = registers.value.find(r => !r.openSession) || registers.value[0] || null
  } catch (e) { ui.error(e.humanMessage) }
})

const canOpen = computed(() => auth.can('REGISTER_OPEN'))
const blocked = computed(() => !selected.value || !!selected.value.openSession || !canOpen.value)

async function open() {
  if (busy.value || !selected.value) return
  if (selected.value.openSession) return ui.error(`Cette caisse est déjà ouverte par ${selected.value.openSession.openedByName}.`)
  busy.value = true
  try {
    const s = await api.pos.openSession(selected.value.id, parseAmount(amount.value))
    auth.setSession({
      id: s.id, registerId: s.registerId, registerCode: s.registerCode, registerName: s.registerName,
      pointOfSaleId: s.pointOfSaleId, pointOfSaleName: s.pointOfSaleName, openedAt: s.openedAt,
      openingFloat: s.openingFloat, openedById: s.openedById, openedByName: s.openedByName
    })
    ui.success(`${s.registerName} ouverte — fond ${fmt(s.openingFloat, true)}`)
    router.replace('/pos')
  } catch (e) { ui.error(e.humanMessage) } finally { busy.value = false }
}
function logout() { auth.logout(); router.replace('/login') }
</script>

<template>
  <div class="page">
    <div class="sheet">
      <header class="head">
        <div>
          <span class="eyebrow">Prise de service</span>
          <h1>Ouverture de caisse</h1>
        </div>
        <div class="row gap-6">
          <router-link v-if="auth.isBackoffice" class="btn" to="/admin"><Icon name="settings" :size="17" />Back-office</router-link>
          <button class="btn ghost" @click="logout"><Icon name="logout" :size="17" />Quitter</button>
        </div>
      </header>

      <div class="who">
        <span class="avatar">{{ (auth.user?.fullName || "?").slice(0, 1).toUpperCase() }}</span>
        <div><b>{{ auth.user?.fullName }}</b><span class="tiny muted">{{ auth.user?.roleName }}</span></div>
      </div>

      <div class="cols">
        <section>
          <h2 class="card-title">Choisissez une caisse</h2>
          <div class="regs">
            <button v-for="r in registers" :key="r.id" class="reg" :class="{ on: selected?.id === r.id, taken: r.openSession }" @click="selected = r">
              <div class="reg-id">
                <b>{{ r.name }}</b>
                <span class="tiny muted">{{ r.pointOfSaleName }} · {{ r.code }}</span>
              </div>
              <span v-if="r.openSession" class="badge warning">{{ r.openSession.openedByName }} · {{ fmtTime(r.openSession.openedAt) }}</span>
              <span v-else class="badge success">Libre</span>
            </button>
            <p v-if="!registers.length" class="empty">Aucune caisse configurée</p>
          </div>
        </section>

        <section>
          <h2 class="card-title">Fond de caisse initial</h2>
          <NumPad v-model="amount" mode="amount" ok-label="Ouvrir la caisse" placeholder="0" @ok="open" />
          <p v-if="!canOpen" class="warn"><Icon name="warning" :size="16" /> Vous n'avez pas la permission d'ouvrir une caisse.</p>
        </section>
      </div>

      <button class="go" :disabled="busy || blocked" @click="open">
        <span>Ouvrir {{ selected?.name || 'la caisse' }}</span>
        <b class="num">{{ fmt(parseAmount(amount), true) }}</b>
      </button>
    </div>
  </div>
</template>

<style scoped>
.page { min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; overflow: auto; background: var(--canvas); }
.sheet { width: min(100%, 940px); background: var(--surface); border: 1px solid var(--line); border-radius: var(--r-xl); padding: 26px 28px 24px; box-shadow: var(--shadow-2); }
.head { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; margin-bottom: 18px; }
.head h1 { font-size: 25px; margin-top: 2px; }

.who { display: flex; align-items: center; gap: 11px; padding: 11px 14px; border-radius: var(--r); background: var(--surface-2); border: 1px solid var(--line); margin-bottom: 20px; }
.who > div { display: flex; flex-direction: column; line-height: 1.2; }
.who b { font-size: 15px; font-weight: 650; }
.avatar { width: 36px; height: 36px; border-radius: 50%; background: var(--ink); color: #fff; display: flex; align-items: center; justify-content: center; font-family: var(--font-display); font-weight: 700; }

.cols { display: grid; grid-template-columns: 1fr 300px; gap: 26px; align-items: start; }
.regs { display: flex; flex-direction: column; gap: 7px; }
.reg {
  display: flex; align-items: center; justify-content: space-between; gap: 12px; min-height: 62px; padding: 10px 14px;
  border: 1px solid var(--line-2); border-radius: var(--r); background: var(--surface); text-align: left;
}
.reg:hover { background: var(--surface-2); }
.reg.on { border-color: var(--brand); background: var(--brand-soft); box-shadow: inset 3px 0 0 var(--brand); }
.reg.taken { opacity: .72; }
.reg-id { display: flex; flex-direction: column; line-height: 1.25; }
.reg-id b { font-family: var(--font-display); font-size: 16px; font-weight: 650; letter-spacing: -.01em; }

.warn { display: flex; align-items: center; gap: 8px; margin: 10px 0 0; font-size: 13.5px; color: var(--warn); }

.go {
  width: 100%; margin-top: 22px; min-height: 66px; padding: 0 24px; border-radius: var(--r-lg);
  display: flex; align-items: center; justify-content: space-between; gap: 14px;
  background: var(--pay); color: #fff; box-shadow: 0 4px 14px -4px rgba(21, 120, 74, .55);
}
.go span { font-family: var(--font-display); font-size: 19px; font-weight: 650; }
.go b { font-family: var(--font-display); font-size: 24px; font-weight: 750; letter-spacing: -.025em; }
.go:hover:not(:disabled) { background: var(--pay-2); }
.go:disabled { background: var(--line); color: var(--ink-4); box-shadow: none; }

@media (max-width: 820px) { .cols { grid-template-columns: 1fr; } }
</style>
