<script setup>
import { useUiStore } from './stores/ui'
import ConfirmDialog from './components/common/ConfirmDialog.vue'
import Icon from './components/common/Icon.vue'
const ui = useUiStore()
</script>
<template>
  <router-view />
  <div class="toasts">
    <div v-for="t in ui.toasts" :key="t.id" class="toast" :class="t.type" @click="ui.dismiss(t.id)">
      <Icon :name="t.type === 'success' ? 'check' : t.type === 'error' ? 'warning' : 'info'" :size="18" :stroke="2.2" />
      <span>{{ t.message }}</span>
    </div>
  </div>
  <ConfirmDialog />
</template>
