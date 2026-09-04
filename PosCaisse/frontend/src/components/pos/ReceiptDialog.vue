<script setup>
/** Shows the tickets produced by a sale (customer + preparation) with a print button (browser printing). */
import { computed, ref } from 'vue'
import Modal from '../common/Modal.vue'
import Icon from '../common/Icon.vue'
import { api } from '../../api'
import { fmt } from '../../utils/money'
import { printJobs } from '../../composables/usePrinter'
const props = defineProps({ jobs: Array, order: Object, title: { type: String, default: 'Tickets' }, autoPrint: Boolean, template: Object })
const emit = defineEmits(['close'])
const active = ref(0)
const width = computed(() => (props.template?.paperWidth || 80) <= 58 ? 220 : 300)
const fontSize = computed(() => props.template?.fontSize || 12)
async function print(all = true) {
  const jobs = all ? props.jobs : [props.jobs[active.value]]
  await printJobs(jobs, props.template)
  try { await api.pos.ackPrint(jobs.map(j => j.id)) } catch { /* ignore */ }
}
if (props.autoPrint && props.jobs?.length) setTimeout(() => print(true), 150)
</script>
<template>
  <Modal size="md" :title="title" @close="emit('close')">
    <div class="rc">
      <div class="jobs">
        <button v-for="(j, i) in jobs" :key="j.id" class="job" :class="{ on: active===i }" @click="active=i">
          <b>{{ j.title }}</b><span class="tiny muted">{{ j.copies }} copie(s){{ j.duplicate ? ' · duplicata' : '' }}</span>
        </button>
        <div v-if="order" class="order-info">
          <div class="tiny muted">TICKET</div><b>{{ order.ticketNumber }}</b>
          <div class="tiny muted mt-8">TOTAL</div><b class="num">{{ fmt(order.total, true) }}</b>
          <template v-if="Number(order.changeAmount) > 0"><div class="tiny muted mt-8">À RENDRE</div><b class="num" style="color:var(--success);font-size:22px">{{ fmt(order.changeAmount, true) }}</b></template>
        </div>
      </div>
      <div class="preview scroll">
        <pre v-if="jobs[active]" class="receipt-paper" :style="{ width: width + 'px', fontSize: fontSize + 'px' }">{{ jobs[active].content }}</pre>
      </div>
    </div>
    <template #foot>
      <button class="btn lg" @click="print(false)"><Icon name="printer" :size="17" />Imprimer celui-ci</button>
      <button class="btn lg primary" @click="print(true)"><Icon name="printer" :size="17" />Imprimer tout ({{ jobs.reduce((s,j)=>s+j.copies,0) }})</button>
      <button class="btn lg success" @click="emit('close')">Fermer</button>
    </template>
  </Modal>
</template>
<style scoped>
.rc { display: grid; grid-template-columns: 200px 1fr; gap: 16px; min-height: 360px; }
.jobs { display: flex; flex-direction: column; gap: 8px; }
.job { text-align: left; display: flex; flex-direction: column; padding: 10px 12px; border-radius: 12px; border: 2px solid var(--border); background: var(--surface-2); min-height: 56px; }
.job.on { border-color: var(--accent); background: var(--accent-soft); }
.order-info { margin-top: auto; padding: 12px; border-radius: 12px; background: var(--surface-2); }
.preview { background: #e2e8f0; padding: 16px; border-radius: 12px; max-height: 60vh; }
@media (max-width: 700px) { .rc { grid-template-columns: 1fr; } }
</style>
