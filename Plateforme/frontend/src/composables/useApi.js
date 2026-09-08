import { ref } from 'vue'
import { useUiStore } from '../stores/ui'

/** Wraps an async API call with a busy flag and human error toasts. Prevents double submit while busy. */
export function useBusy() {
  const busy = ref(false)
  const ui = useUiStore()
  async function run(fn, { success, rethrow = false } = {}) {
    if (busy.value) return undefined
    busy.value = true
    try {
      const r = await fn()
      if (success) ui.success(typeof success === 'function' ? success(r) : success)
      return r
    } catch (e) {
      ui.error(e.humanMessage || e.message || 'Erreur')
      if (rethrow) throw e
      return undefined
    } finally { busy.value = false }
  }
  return { busy, run }
}
