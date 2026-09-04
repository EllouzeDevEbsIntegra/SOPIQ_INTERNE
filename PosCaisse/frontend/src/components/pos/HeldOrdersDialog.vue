<script setup>
import { onMounted, ref } from 'vue'
import Modal from '../common/Modal.vue'
import { api } from '../../api'
import { useAuthStore } from '../../stores/auth'
import { useUiStore } from '../../stores/ui'
import { fmt } from '../../utils/money'
import { fmtTime } from '../../utils/dates'
const emit = defineEmits(['close', 'resume'])
const auth = useAuthStore(); const ui = useUiStore()
const orders = ref([]); const loading = ref(true)
async function load() { loading.value = true; try { orders.value = await api.pos.held(auth.session?.pointOfSaleId) } catch (e) { ui.error(e.humanMessage) } finally { loading.value = false } }
onMounted(load)
async function abandon(o) {
  if (!await ui.confirm({ title: 'Abandonner la commande', message: `Abandonner ${o.heldRef} (${fmt(o.total, true)}) ?`, okLabel: 'Abandonner', danger: true })) return
  try { await api.pos.abandon(o.id); ui.success('Commande abandonnée'); load() } catch (e) { ui.error(e.humanMessage) }
}
</script>
<template>
  <Modal size="md" title="Commandes en attente" @close="emit('close')">
    <div v-if="loading" class="spinner"></div>
    <div v-else-if="!orders.length" class="empty">Aucune commande en attente</div>
    <div v-else class="list">
      <div v-for="o in orders" :key="o.id" class="held">
        <div class="grow">
          <div class="row gap-8"><b style="font-size:18px">{{ o.heldRef }}</b><span class="badge">{{ fmtTime(o.createdAt) }}</span><span class="badge info">{{ o.cashierName }}</span><span v-if="o.customerName" class="badge accent">👤 {{ o.customerName }}</span></div>
          <div class="muted small">{{ o.lines.map(l => Number(l.quantity) + '× ' + l.productName).join(', ') }}</div>
        </div>
        <b class="num" style="font-size:20px">{{ fmt(o.total, true) }}</b>
        <button class="btn danger" @click="abandon(o)" v-if="auth.can('ORDER_CANCEL')">✕</button>
        <button class="btn success lg" @click="emit('resume', o)">REPRENDRE</button>
      </div>
    </div>
  </Modal>
</template>
<style scoped>
.list { display: flex; flex-direction: column; gap: 8px; }
.held { display: flex; align-items: center; gap: 12px; padding: 12px; border-radius: 12px; background: var(--surface-2); border: 1px solid var(--border); }
</style>
