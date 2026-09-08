<script setup>
/** Generic numeric input dialog (quantity, price, discount %, amount…) built on the reusable NumPad. */
import { ref } from 'vue'
import Modal from '../common/Modal.vue'
import NumPad from '../common/NumPad.vue'
const props = defineProps({ title: String, mode: { type: String, default: 'amount' }, initial: [Number, String], hint: String, okLabel: { type: String, default: 'OK' }, options: Array })
const emit = defineEmits(['close', 'ok'])
const hasInitial = props.initial !== undefined && props.initial !== null && props.initial !== ''
const placeholder = hasInitial ? String(props.initial).replace('.', ',') : ''
const value = ref('')
function ok(v) { emit('ok', value.value === '' && hasInitial ? Number(props.initial) : v) }
</script>
<template>
  <Modal :title="title" @close="emit('close')">
    <p v-if="hint" class="muted" style="margin-top:0">{{ hint }}</p>
    <div v-if="options?.length" class="row wrap gap-8 mb-8">
      <button v-for="o in options" :key="o.label" class="btn chip" @click="emit('ok', o.value)">{{ o.label }}</button>
    </div>
    <NumPad v-model="value" :mode="mode" :ok-label="okLabel" :placeholder="placeholder" @ok="ok" />
  </Modal>
</template>
