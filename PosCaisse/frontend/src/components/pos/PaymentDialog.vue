<script setup>
/** Touch payment: cash quick buttons, exact amount, mixed payments, instant change. Emits 'confirm' with payments[]. */
import { computed, ref, watch } from 'vue'
import Modal from '../common/Modal.vue'
import NumPad from '../common/NumPad.vue'
import { useCatalogStore } from '../../stores/catalog'
import { fmt, add, sub, round, parseAmount } from '../../utils/money'
const props = defineProps({ total: Number, busy: Boolean })
const emit = defineEmits(['close', 'confirm'])
const catalog = useCatalogStore()
const methods = computed(() => catalog.paymentMethods)
const current = ref(methods.value.find(m => m.kind === 'CASH') || methods.value[0])
const entry = ref('')
const payments = ref([]) // {method, amount, tendered}
const paid = computed(() => payments.value.reduce((s, p) => add(s, p.amount), 0))
const remaining = computed(() => Math.max(0, sub(props.total, paid.value)))
const entryValue = computed(() => parseAmount(entry.value))
const isCash = computed(() => current.value?.kind === 'CASH')
const changePreview = computed(() => isCash.value && entryValue.value > remaining.value ? sub(entryValue.value, remaining.value) : 0)
const change = computed(() => payments.value.reduce((s, p) => add(s, p.tendered > p.amount ? sub(p.tendered, p.amount) : 0), 0))
const done = computed(() => remaining.value <= 0 && payments.value.length > 0)
const quick = computed(() => catalog.quickCash)

function pick(m) { current.value = m; entry.value = '' }
function addPayment(amountGiven) {
  const given = amountGiven ?? entryValue.value
  if (given <= 0 || remaining.value <= 0) return
  const applied = isCash.value ? Math.min(given, remaining.value) : Math.min(given, remaining.value)
  if (!isCash.value && given > remaining.value) { /* card can't overpay: clamp */ }
  payments.value.push({ method: current.value, amount: round(applied), tendered: isCash.value ? round(given) : round(applied) })
  entry.value = ''
}
function exact() { addPayment(remaining.value) }
function removePayment(i) { payments.value.splice(i, 1) }
function confirm() {
  if (!done.value || props.busy) return
  emit('confirm', payments.value.map(p => ({ paymentMethodId: p.method.id, amount: p.amount, tendered: p.method.kind === 'CASH' ? p.tendered : null })))
}
watch(done, d => { if (d && !isCash.value) { /* auto-focus validate */ } })
function onKey(e) { if (e.key === 'Enter' && done.value) confirm() }
</script>
<template>
  <Modal size="lg" title="Encaissement" @close="!busy && emit('close')" :closable="!busy">
    <div class="pay" @keydown="onKey">
      <div class="left">
        <div class="due">
          <div class="drow"><span>À PAYER</span><b class="num">{{ fmt(total, true) }}</b></div>
          <div class="drow" v-if="payments.length"><span>REÇU</span><b class="num">{{ fmt(paid + change) }}</b></div>
          <div class="drow rest" :class="{ ok: remaining<=0 }"><span>{{ remaining > 0 ? 'RESTE' : 'À RENDRE' }}</span><b class="num">{{ fmt(remaining > 0 ? remaining : change, true) }}</b></div>
        </div>
        <div class="methods">
          <button v-for="m in methods" :key="m.id" class="method" :class="{ on: current?.id===m.id }" @click="pick(m)">
            <span class="ico">{{ { CASH: '💵', CARD: '💳', CHECK: '🧾', MEAL_VOUCHER: '🎫', OTHER: '•' }[m.kind] }}</span>{{ m.name }}
          </button>
        </div>
        <div class="plist" v-if="payments.length">
          <div v-for="(p, i) in payments" :key="i" class="prow">
            <span>{{ p.method.name }}<span v-if="p.tendered > p.amount" class="muted small"> (reçu {{ fmt(p.tendered) }}, rendu {{ fmt(sub(p.tendered, p.amount)) }})</span></span>
            <span class="num bold">{{ fmt(p.amount) }}</span>
            <button class="btn sm ghost" @click="removePayment(i)">✕</button>
          </div>
        </div>
      </div>
      <div class="right">
        <div class="quick" v-if="isCash">
          <button v-for="q in quick" :key="q" class="btn lg" @click="addPayment(q)" :disabled="remaining<=0">{{ q }} {{ catalog.company?.currencySymbol || 'DT' }}</button>
          <button class="btn lg accent exact" @click="exact" :disabled="remaining<=0">MONTANT EXACT — {{ fmt(remaining) }}</button>
        </div>
        <div class="quick" v-else><button class="btn lg accent block" @click="exact" :disabled="remaining<=0">{{ current?.name }} — {{ fmt(remaining, true) }}</button></div>
        <NumPad v-model="entry" mode="amount" :ok-label="isCash ? 'REÇU' : 'AJOUTER'" :placeholder="fmt(remaining)" @ok="addPayment()" />
        <div v-if="changePreview" class="chg">À rendre : <b class="num">{{ fmt(changePreview, true) }}</b></div>
      </div>
    </div>
    <template #foot>
      <button class="btn lg" :disabled="busy" @click="emit('close')">Annuler</button>
      <button class="btn success xl grow" :disabled="!done || busy" @click="confirm">{{ busy ? 'ENREGISTREMENT…' : 'VALIDER LE PAIEMENT' }}</button>
    </template>
  </Modal>
</template>
<style scoped>
.pay { display: grid; grid-template-columns: 1.1fr 1fr; gap: 20px; }
.due { background: var(--primary); color: #fff; border-radius: 14px; padding: 14px 16px; margin-bottom: 12px; }
.drow { display: flex; justify-content: space-between; align-items: baseline; font-size: 15px; opacity: .85; padding: 2px 0; } .drow b { font-size: 24px; }
.drow.rest { opacity: 1; color: #fdba74; } .drow.rest b { font-size: 34px; } .drow.rest.ok { color: #86efac; }
.methods { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 8px; margin-bottom: 12px; }
.method { min-height: 60px; border-radius: 12px; border: 2px solid var(--border); background: var(--surface-2); font-weight: 700; display: flex; align-items: center; gap: 8px; padding: 0 12px; }
.method.on { border-color: var(--accent); background: var(--accent-soft); } .ico { font-size: 22px; }
.plist { border: 1px solid var(--border); border-radius: 12px; overflow: hidden; }
.prow { display: flex; align-items: center; gap: 10px; padding: 8px 12px; border-bottom: 1px solid var(--border); } .prow > span:first-child { flex: 1; }
.quick { display: grid; grid-template-columns: repeat(auto-fit, minmax(90px, 1fr)); gap: 8px; margin-bottom: 10px; } .quick .exact { grid-column: 1 / -1; }
.chg { margin-top: 8px; text-align: right; font-size: 18px; color: var(--success); }
@media (max-width: 760px) { .pay { grid-template-columns: 1fr; } }
</style>
