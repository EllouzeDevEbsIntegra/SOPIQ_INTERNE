<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { api } from '../api'
import { useAuthStore } from '../stores/auth'
import { useUiStore } from '../stores/ui'
import NumPad from '../components/common/NumPad.vue'
import Icon from '../components/common/Icon.vue'

const router = useRouter(); const route = useRoute(); const auth = useAuthStore(); const ui = useUiStore()
const users = ref([]); const selected = ref(null); const pin = ref(''); const busy = ref(false)
const mode = ref('pin'); const username = ref(''); const password = ref(''); const offline = ref(false)
const company = ref(null)

onMounted(async () => {
  try { users.value = await api.auth.users() } catch (e) { offline.value = true; ui.error(e.humanMessage) }
  try { company.value = await api.auth.branding() } catch { /* identité non disponible : sans conséquence */ }
})

const initials = (name) => name.split(/\s+/).slice(0, 2).map(w => w[0]).join('').toUpperCase()
const label = computed(() => selected.value ? `PIN de ${selected.value.fullName}` : 'Saisissez votre code PIN')

function pick(u) { selected.value = selected.value?.id === u.id ? null : u; pin.value = '' }

async function submitPin(p) {
  if (busy.value || !p || p.length < 4) return
  busy.value = true
  try { await auth.loginPin(selected.value?.id ?? null, p); go() }
  catch (e) { ui.error(e.humanMessage); pin.value = '' }
  finally { busy.value = false }
}
async function submitPassword() {
  if (busy.value) return
  busy.value = true
  try { await auth.loginPassword(username.value, password.value); go() }
  catch (e) { ui.error(e.humanMessage) }
  finally { busy.value = false }
}
function go() {
  const target = route.query.redirect && String(route.query.redirect)
  if (target && !target.startsWith('/login')) return router.replace(target)
  if (auth.can('SELL')) router.replace(auth.session ? '/pos' : '/open')
  else router.replace('/admin')
}
</script>

<template>
  <div class="login">
    <!-- panneau de marque -->
    <aside class="brand">
      <div class="mark"><Icon name="store" :size="26" /></div>
      <h1>PosCaisse</h1>
      <p class="lede">Caisse tactile pour la restauration rapide</p>
      <div class="brand-foot">
        <span v-if="company" class="shop">{{ company.tradeName || company.name }}</span>
        <span class="tiny">Sélectionnez votre profil, puis composez votre code.</span>
      </div>
    </aside>

    <!-- panneau d'accès -->
    <main class="access">
      <nav class="tabs">
        <button :class="{ on: mode === 'pin' }" @click="mode = 'pin'">Caissier</button>
        <button :class="{ on: mode === 'password' }" @click="mode = 'password'">Administration</button>
      </nav>

      <template v-if="mode === 'pin'">
        <div class="people" v-if="users.length">
          <button v-for="u in users" :key="u.id" class="person" :class="{ on: selected?.id === u.id }" :style="{ '--c': u.color || '#8A8178' }" @click="pick(u)">
            <span class="avatar">{{ initials(u.fullName) }}</span>
            <span class="who">
              <b>{{ u.fullName }}</b>
              <em>{{ u.roleName }}</em>
            </span>
          </button>
        </div>
        <p v-else-if="offline" class="offline">
          <Icon name="warning" :size="18" /> Serveur injoignable — vérifiez que le backend est démarré.
        </p>

        <p class="prompt">{{ label }}</p>
        <NumPad v-model="pin" mode="pin" ok-label="Entrer" :max-len="8" @ok="submitPin" />
      </template>

      <form v-else class="form" @submit.prevent="submitPassword">
        <div class="field">
          <label>Identifiant</label>
          <input class="input" v-model="username" autocomplete="username" autofocus />
        </div>
        <div class="field">
          <label>Mot de passe</label>
          <input class="input" type="password" v-model="password" autocomplete="current-password" />
        </div>
        <button class="btn primary lg block" :disabled="busy">Se connecter</button>
      </form>
    </main>
  </div>
</template>

<style scoped>
.login { height: 100vh; display: grid; grid-template-columns: minmax(300px, 38%) 1fr; background: var(--canvas); }

/* --- marque --- */
.brand {
  display: flex; flex-direction: column; padding: 46px 44px;
  background: var(--ink); color: #E8E2DA;
  background-image: radial-gradient(700px 380px at 12% -8%, rgba(200, 68, 28, .3), transparent 70%);
}
.mark {
  width: 52px; height: 52px; display: flex; align-items: center; justify-content: center;
  border-radius: var(--r-lg); background: var(--brand); color: #fff; margin-bottom: 22px;
}
.brand h1 { font-size: 34px; font-weight: 700; letter-spacing: -.03em; color: #fff; }
.lede { margin: 8px 0 0; font-size: 15.5px; line-height: 1.5; color: #A69C90; max-width: 30ch; }
.brand-foot { margin-top: auto; display: flex; flex-direction: column; gap: 5px; }
.shop { font-family: var(--font-display); font-size: 15px; font-weight: 650; color: #fff; letter-spacing: -.01em; }
.brand-foot .tiny { color: #7C7167; }

/* --- accès --- */
.access { display: flex; flex-direction: column; gap: 14px; padding: 32px 40px; overflow: auto; max-width: 560px; width: 100%; margin: 0 auto; justify-content: center; }
.tabs { margin-bottom: 2px; }

.people { display: grid; grid-template-columns: repeat(auto-fill, minmax(178px, 1fr)); gap: 8px; max-height: 32vh; overflow: auto; padding: 2px; }
.person {
  display: flex; align-items: center; gap: 10px; padding: 8px 11px; min-height: 56px;
  background: var(--surface); border: 1px solid var(--line); border-radius: var(--r); text-align: left;
  transition: border-color .12s, box-shadow .12s, background .12s;
}
.person:hover { border-color: var(--line-2); }
.person.on { border-color: var(--c); box-shadow: 0 0 0 2px color-mix(in srgb, var(--c) 26%, transparent); }
.avatar {
  width: 38px; height: 38px; flex: none; border-radius: 50%; background: var(--c); color: #fff;
  display: flex; align-items: center; justify-content: center;
  font-family: var(--font-display); font-size: 14px; font-weight: 700; letter-spacing: .02em;
}
.who { display: flex; flex-direction: column; min-width: 0; }
.who b { font-size: 14.5px; font-weight: 650; letter-spacing: -.01em; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.who em { font-style: normal; font-size: 11px; font-weight: 700; letter-spacing: .07em; text-transform: uppercase; color: var(--ink-3); }

.prompt { margin: 4px 0 0; text-align: center; font-size: 14.5px; font-weight: 600; color: var(--ink-2); }
.offline { display: flex; align-items: center; gap: 9px; padding: 12px 14px; border-radius: var(--r); background: var(--warn-soft); border: 1px solid var(--warn-line); color: var(--warn); font-size: 14px; margin: 0; }
.form { display: flex; flex-direction: column; gap: 16px; }

@media (max-width: 900px) {
  .login { grid-template-columns: 1fr; grid-template-rows: auto 1fr; }
  .brand { padding: 24px 26px; }
  .brand h1 { font-size: 26px; } .lede { display: none; } .brand-foot { margin-top: 12px; }
  .mark { width: 42px; height: 42px; margin-bottom: 14px; }
  .access { padding: 22px; justify-content: flex-start; }
}
</style>
