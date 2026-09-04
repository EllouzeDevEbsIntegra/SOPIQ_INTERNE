<script setup>
/**
 * Reusable touch numeric keypad. Modes: 'amount' (decimal, 3 dec), 'integer', 'pin' (masked).
 * v-model is a string being typed; emits 'ok' with the numeric value (or the string for pin).
 */
import { computed, watch } from 'vue'
import { decimals, fmt } from '../../utils/money'
const props = defineProps({ modelValue: { type: String, default: '' }, mode: { type: String, default: 'amount' }, okLabel: { type: String, default: 'OK' }, showDisplay: { type: Boolean, default: true }, maxLen: { type: Number, default: 12 }, autoOk: { type: Number, default: 0 }, placeholder: { type: String, default: '' } })
const emit = defineEmits(['update:modelValue', 'ok'])
const value = computed(() => props.modelValue || '')
function set(v) { emit('update:modelValue', v) }
function press(k) {
  let v = value.value
  if (k === 'C') { set(''); return }
  if (k === '⌫') { set(v.slice(0, -1)); return }
  if (k === ',') { if (props.mode !== 'amount' || v.includes(',')) return; set((v || '0') + ','); return }
  if (v.length >= props.maxLen) return
  if (props.mode === 'amount' && v.includes(',') && v.split(',')[1].length >= decimals()) return
  if (v === '0' && k !== ',' && props.mode !== 'pin') v = ''
  set(v + k)
}
const numeric = computed(() => Number((value.value || '0').replace(',', '.')) || 0)
function ok() { emit('ok', props.mode === 'pin' ? value.value : numeric.value) }
const display = computed(() => props.mode === 'pin' ? '●'.repeat(value.value.length) : (value.value || props.placeholder || '0'))
watch(value, v => { if (props.autoOk && props.mode === 'pin' && v.length === props.autoOk) ok() })
function onKey(e) {
  if (e.key >= '0' && e.key <= '9') press(e.key)
  else if (e.key === '.' || e.key === ',') press(',')
  else if (e.key === 'Backspace') press('⌫')
  else if (e.key === 'Enter') ok()
  else if (e.key === 'Escape') press('C')
  else return
  e.preventDefault()
}
defineExpose({ press, onKey })
</script>
<template>
  <div class="col gap-8" tabindex="0" @keydown="onKey">
    <div v-if="showDisplay" class="numpad-display" :class="{ pin: mode==='pin' }">{{ display }}</div>
    <div class="numpad">
      <button v-for="k in ['7','8','9','4','5','6','1','2','3']" :key="k" type="button" @click="press(k)">{{ k }}</button>
      <button type="button" class="act" @click="press('C')">C</button>
      <button type="button" @click="press('0')">0</button>
      <button v-if="mode==='amount'" type="button" @click="press(',')">,</button>
      <button v-else type="button" class="act" @click="press('⌫')">⌫</button>
      <button v-if="mode==='amount'" type="button" class="act" @click="press('⌫')">⌫</button>
      <button type="button" class="ok" :class="{ wide: mode!=='amount' }" @click="ok">{{ okLabel }}</button>
    </div>
    <div v-if="mode==='amount' && showDisplay" class="tiny muted right">{{ fmt(numeric, true) }}</div>
  </div>
</template>
