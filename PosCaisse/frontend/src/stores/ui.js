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
  const success = (m) => toast(m, 'success', 2500)
  const error = (m) => toast(m, 'error', 5000)
  const info = (m) => toast(m, 'info')

  // confirm dialog
  const confirmState = ref(null)
  function confirm({ title, message, okLabel = 'Confirmer', cancelLabel = 'Annuler', danger = false }) {
    return new Promise(resolve => { confirmState.value = { title, message, okLabel, cancelLabel, danger, resolve } })
  }
  function resolveConfirm(v) { const s = confirmState.value; confirmState.value = null; s && s.resolve(v) }
  return { toasts, toast, dismiss, success, error, info, confirmState, confirm, resolveConfirm }
})
