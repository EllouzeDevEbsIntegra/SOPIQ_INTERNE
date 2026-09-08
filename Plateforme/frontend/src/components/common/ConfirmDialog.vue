<script setup>
import Modal from './Modal.vue'
import { useUiStore } from '../../stores/ui'
const ui = useUiStore()
</script>
<template>
  <Modal v-if="ui.confirmState" :title="ui.confirmState.title" @close="ui.resolveConfirm(false)">
    <p style="font-size:17px;margin:0;white-space:pre-line">{{ ui.confirmState.message }}</p>
    <template #foot>
      <button class="btn lg" @click="ui.resolveConfirm(false)">{{ ui.confirmState.cancelLabel }}</button>
      <button class="btn lg" :class="ui.confirmState.danger ? 'danger solid' : 'primary'" @click="ui.resolveConfirm(true)">{{ ui.confirmState.okLabel }}</button>
    </template>
  </Modal>
</template>
