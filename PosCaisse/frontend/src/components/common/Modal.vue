<script setup>
import Icon from './Icon.vue'
defineProps({ title: String, size: { type: String, default: '' }, closable: { type: Boolean, default: true } })
const emit = defineEmits(['close'])
</script>
<template>
  <div class="modal-backdrop" @mousedown.self="closable && emit('close')">
    <div class="modal" :class="size" role="dialog">
      <div class="modal-head" v-if="title || $slots.head">
        <slot name="head"><h2>{{ title }}</h2></slot>
        <button v-if="closable" class="btn ghost icon" @click="emit('close')" aria-label="Fermer"><Icon name="close" :size="18" /></button>
      </div>
      <div class="modal-body"><slot /></div>
      <div class="modal-foot" v-if="$slots.foot"><slot name="foot" /></div>
    </div>
  </div>
</template>
