<script setup>
import { onMounted, ref } from 'vue'
import Modal from '../common/Modal.vue'
import Icon from '../common/Icon.vue'
import NumPad from '../common/NumPad.vue'
import { api } from '../../api'
import { useAuthStore } from '../../stores/auth'
import { useUiStore } from '../../stores/ui'
import { fmt } from '../../utils/money'
import { fmtTime } from '../../utils/dates'
const emit = defineEmits(['close'])
const auth = useAuthStore(); const ui = useUiStore()
const type = ref('OUT'); const reason = ref(''); const comment = ref(''); const amount = ref(''); const busy = ref(false); const list = ref([])
const reasons = { OUT: ['Achat urgent', 'Retrait coffre', 'Paiement fournisseur', 'Remboursement client', 'Autre'], IN: ['Ajout monnaie', 'Apport coffre', 'Correction', 'Autre'] }
async function load() { try { list.value = await api.pos.movements(auth.session.id) } catch { /* ignore */ } }
onMounted(load)
async function save(v) {
  if (busy.value) return
  if (!reason.value.trim()) return ui.error('Indiquez un motif.')
  if (!v || v <= 0) return ui.error('Saisissez un montant supérieur à zéro.')
  busy.value = true
  try { await api.pos.addMovement(auth.session.id, { type: type.value, reason: reason.value, amount: v, comment: comment.value || null }); ui.success((type.value === 'OUT' ? 'Sortie' : 'Entrée') + ' de ' + fmt(v, true) + ' enregistrée'); amount.value = ''; comment.value = ''; load() }
  catch (e) { ui.error(e.humanMessage) } finally { busy.value = false }
}
</script>
<template>
  <Modal size="md" title="Mouvement de caisse" @close="emit('close')">
    <div class="grid">
      <div class="col gap-8">
        <div class="row gap-8"><button class="btn lg grow" :class="{ 'danger solid': type==='OUT' }" @click="type='OUT'"><Icon name="arrowUp" :size="18" />Sortie</button><button class="btn lg grow" :class="{ success: type==='IN' }" @click="type='IN'"><Icon name="arrowDown" :size="18" />Entrée</button></div>
        <div class="field"><label>Motif</label><div class="row wrap gap-6"><button v-for="r in reasons[type]" :key="r" class="btn chip" :class="{ on: reason===r }" @click="reason=r">{{ r }}</button></div><input class="input" v-model="reason" placeholder="Motif" /></div>
        <div class="field"><label>Commentaire</label><input class="input" v-model="comment" placeholder="ex. Achat pain" /></div>
        <div class="field" v-if="list.length"><label>Mouvements de la session</label>
          <div class="hist scroll"><div v-for="m in list" :key="m.id" class="row between small"><span>{{ fmtTime(m.createdAt) }} · {{ m.type==='OUT' ? '↑' : '↓' }} {{ m.reason }}</span><b class="num" :style="{ color: m.type==='OUT' ? 'var(--danger)' : 'var(--success)' }">{{ m.type==='OUT' ? '−' : '+' }}{{ fmt(m.amount) }}</b></div></div>
        </div>
      </div>
      <div><NumPad v-model="amount" mode="amount" :ok-label="type === 'OUT' ? 'Enregistrer la sortie' : 'Enregistrer l\'entrée'" @ok="save" /></div>
    </div>
  </Modal>
</template>
<style scoped>
.grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; } .hist { max-height: 160px; padding: 6px 8px; border: 1px solid var(--border); border-radius: 10px; }
@media (max-width: 700px) { .grid { grid-template-columns: 1fr; } }
</style>
