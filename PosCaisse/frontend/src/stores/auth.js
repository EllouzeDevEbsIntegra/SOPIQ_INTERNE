import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { api } from '../api'
import { setToken, setUnauthorizedHandler } from '../api/http'

const KEY = 'poscaisse.token'
export const useAuthStore = defineStore('auth', () => {
  const token = ref(null)
  const user = ref(null)
  const session = ref(null)      // open register session of the current user (null if none)
  const ready = ref(false)

  try { token.value = localStorage.getItem(KEY) } catch { /* ignore */ }
  setToken(token.value)

  const isAuthenticated = computed(() => !!user.value)
  const permissions = computed(() => new Set(user.value?.permissions || []))
  const can = (perm) => permissions.value.has(perm)
  const isBackoffice = computed(() => can('BACKOFFICE_ACCESS'))

  function apply(res) {
    if (res.token) { token.value = res.token; setToken(res.token); try { localStorage.setItem(KEY, res.token) } catch { /* ignore */ } }
    user.value = res.user
    session.value = res.openSession || null
  }
  async function loginPin(userId, pin) { apply(await api.auth.pin(userId, pin)); return user.value }
  async function loginPassword(username, password) { apply(await api.auth.login(username, password)); return user.value }
  async function restore() {
    if (token.value && !user.value) {
      try { apply(await api.auth.me()) } catch { logout(false) }
    }
    ready.value = true
  }
  function logout(callApi = true) {
    if (callApi && token.value) api.auth.logout().catch(() => {})
    token.value = null; user.value = null; session.value = null
    setToken(null)
    try { localStorage.removeItem(KEY) } catch { /* ignore */ }
  }
  function setSession(s) { session.value = s }
  setUnauthorizedHandler(() => { if (user.value) logout(false) })
  return { token, user, session, ready, isAuthenticated, can, isBackoffice, loginPin, loginPassword, restore, logout, setSession }
})
