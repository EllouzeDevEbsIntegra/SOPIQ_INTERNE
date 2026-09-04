<script setup>
import { onMounted, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { api } from '../api'
import { useAuthStore } from '../stores/auth'
import { useUiStore } from '../stores/ui'
import NumPad from '../components/common/NumPad.vue'

const router = useRouter(); const route = useRoute(); const auth = useAuthStore(); const ui = useUiStore()
const users = ref([]); const selected = ref(null); const pin = ref(''); const busy = ref(false); const mode = ref('pin')
const username = ref(''); const password = ref(''); const offline = ref(false)

onMounted(async () => {
  try { users.value = await api.auth.users() } catch (e) { offline.value = true; ui.error(e.humanMessage) }
})
function pick(u) { selected.value = u; pin.value = '' }
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
    <div class="login-card">
      <div class="brand"><span class="logo">🧾</span><div><h1>PosCaisse</h1><div class="muted small">Caisse tactile</div></div></div>
      <div class="tabs">
        <button :class="{ on: mode==='pin' }" @click="mode='pin'">Connexion PIN</button>
        <button :class="{ on: mode==='password' }" @click="mode='password'">Administration</button>
      </div>
      <template v-if="mode==='pin'">
        <div class="users" v-if="users.length">
          <button v-for="u in users" :key="u.id" class="user-tile" :class="{ on: selected?.id===u.id }" :style="{ '--c': u.color || '#64748b' }" @click="pick(u)">
            <span class="avatar">{{ u.fullName.slice(0,1).toUpperCase() }}</span>
            <span class="name">{{ u.fullName }}</span>
            <span class="role">{{ u.roleName }}</span>
          </button>
        </div>
        <p v-else-if="offline" class="muted center">Serveur injoignable. Vérifiez que le backend est démarré.</p>
        <p class="hint">{{ selected ? `PIN de ${selected.fullName}` : 'Choisissez votre nom puis saisissez votre PIN (ou tapez directement votre PIN)' }}</p>
        <NumPad v-model="pin" mode="pin" ok-label="ENTRER" :auto-ok="0" @ok="submitPin" :max-len="8" />
      </template>
      <form v-else class="col gap-16" @submit.prevent="submitPassword">
        <div class="field"><label>Identifiant</label><input class="input lg-text" v-model="username" autocomplete="username" autofocus /></div>
        <div class="field"><label>Mot de passe</label><input class="input" type="password" v-model="password" autocomplete="current-password" /></div>
        <button class="btn primary lg block" :disabled="busy">Se connecter</button>
      </form>
    </div>
  </div>
</template>
<style scoped>
.login { min-height: 100vh; display: flex; align-items: center; justify-content: center; background: radial-gradient(1200px 600px at 20% -10%, #1e293b, #0f172a); padding: 16px; overflow: auto; }
.login-card { background: var(--surface); border-radius: 22px; padding: 26px; width: min(100%, 520px); box-shadow: var(--shadow-lg); }
.brand { display: flex; align-items: center; gap: 14px; margin-bottom: 14px; } .brand h1 { font-size: 26px; } .logo { font-size: 38px; }
.users { display: grid; grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); gap: 10px; margin-bottom: 14px; max-height: 260px; overflow: auto; }
.user-tile { display: flex; flex-direction: column; align-items: center; gap: 4px; padding: 12px 8px; border-radius: 14px; border: 2px solid var(--border); background: var(--surface-2); min-height: 100px; }
.user-tile.on { border-color: var(--c); background: #fff; box-shadow: 0 0 0 3px color-mix(in srgb, var(--c) 25%, transparent); }
.avatar { width: 42px; height: 42px; border-radius: 50%; background: var(--c); color: #fff; font-weight: 800; font-size: 18px; display: flex; align-items: center; justify-content: center; }
.name { font-weight: 700; } .role { font-size: 11px; color: var(--text-3); text-transform: uppercase; letter-spacing: .05em; }
.hint { text-align: center; color: var(--text-2); margin: 6px 0 10px; min-height: 22px; }
</style>
