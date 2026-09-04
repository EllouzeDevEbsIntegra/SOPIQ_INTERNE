<script setup>
import { useUiStore } from './stores/ui'
import ConfirmDialog from './components/common/ConfirmDialog.vue'
const ui = useUiStore()
</script>
<template>
  <router-view />
  <div class="toasts">
    <div v-for="t in ui.toasts" :key="t.id" class="toast" :class="t.type" @click="ui.dismiss(t.id)">
      <span v-if="t.type==='success'">✓</span><span v-else-if="t.type==='error'">⚠</span><span v-else>ℹ</span>
      <span>{{ t.message }}</span>
    </div>
  </div>
  <ConfirmDialog />
</template>
