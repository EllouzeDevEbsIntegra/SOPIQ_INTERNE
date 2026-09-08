import { defineStore } from 'pinia'
import { ref } from 'vue'

let seq = 0
export const useUiStore = defineStore('ui', () => {
  const toasts = ref([])
  function toast(message, type = 'info', ms = 3500) {
    const id = ++seq
    toasts.value.push({ id, message, type })
    setTimeout(() => dismiss(id), ms)
    return id
  }
  function dismiss(id) { toasts.value = toasts.value.filter(t => t.id !== id) }

  /**
   * Texte d'une notification, qu'on lui passe un message ou une exception.
   *
   * Les appelants passent le plus souvent `e.humanMessage`, que l'intercepteur HTTP
   * pose sur les erreurs d'API. Une erreur de programmation (un appel vers une fonction
   * qui n'existe pas, par exemple) ne passe jamais par cet intercepteur : le champ est
   * alors absent, et la pastille s'affichait rouge et muette — l'utilisateur voyait
   * qu'il y avait une erreur sans savoir laquelle, et la console restait vide puisque
   * l'exception avait été rattrapée. On retombe donc sur un texte générique, et on
   * journalise ce qui a échappé au filet pour que le cas soit visible au développement.
   */
  function messageOf(m) {
    if (typeof m === 'string') return m.trim()
    if (m && typeof m === 'object') return String(m.humanMessage || m.message || '').trim()
    return ''
  }
  const GENERIC = "Une erreur inattendue est survenue. Réessayez ; si cela se reproduit, prévenez l'administrateur."

  const success = (m) => toast(messageOf(m) || 'Opération effectuée.', 'success', 2500)
  function error(m) {
    const text = messageOf(m)
    if (!text) console.error('[PosCaisse] erreur sans message :', m)
    return toast(text || GENERIC, 'error', 5000)
  }
  const info = (m) => toast(messageOf(m) || '', 'info')

  // confirm dialog
  const confirmState = ref(null)
  function confirm({ title, message, okLabel = 'Confirmer', cancelLabel = 'Annuler', danger = false }) {
    return new Promise(resolve => { confirmState.value = { title, message, okLabel, cancelLabel, danger, resolve } })
  }
  function resolveConfirm(v) { const s = confirmState.value; confirmState.value = null; s && s.resolve(v) }
  return { toasts, toast, dismiss, success, error, info, confirmState, confirm, resolveConfirm }
})
