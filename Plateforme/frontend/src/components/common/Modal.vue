<script setup>
import { nextTick, onMounted, onUnmounted, ref, useId } from 'vue'
import Icon from './Icon.vue'
const props = defineProps({ title: String, size: { type: String, default: '' }, closable: { type: Boolean, default: true } })
const emit = defineEmits(['close'])
const dialogue = ref(null)
const titreId = useId()
let precedent = null

const selectionnables = () => [...(dialogue.value?.querySelectorAll(
  'button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [href], [tabindex]:not([tabindex="-1"])'
) || [])].filter(e => e.getClientRects().length)

function clavier(e) {
  if (e.key === 'Escape' && props.closable) { e.preventDefault(); e.stopPropagation(); emit('close'); return }
  if (e.key !== 'Tab') return
  const liste = selectionnables()
  if (!liste.length) { e.preventDefault(); dialogue.value?.focus(); return }
  const premier = liste[0], dernier = liste[liste.length - 1]
  if (e.shiftKey && document.activeElement === premier) { e.preventDefault(); dernier.focus() }
  else if (!e.shiftKey && document.activeElement === dernier) { e.preventDefault(); premier.focus() }
}

onMounted(async () => {
  precedent = document.activeElement
  await nextTick()
  const autofocus = dialogue.value?.querySelector('[autofocus]')
  ;(autofocus || selectionnables()[0] || dialogue.value)?.focus()
})
onUnmounted(() => { if (precedent?.isConnected) precedent.focus() })
</script>
<template>
  <div class="modal-backdrop" @mousedown.self="closable && emit('close')">
    <div ref="dialogue" class="modal" :class="size" role="dialog" aria-modal="true"
         :aria-labelledby="title ? titreId : undefined" tabindex="-1" @keydown="clavier">
      <div class="modal-head" v-if="title || $slots.head">
        <slot name="head"><h2 :id="titreId">{{ title }}</h2></slot>
        <button v-if="closable" class="btn ghost icon" @click="emit('close')" aria-label="Fermer"><Icon name="close" :size="18" /></button>
      </div>
      <div class="modal-body"><slot /></div>
      <div class="modal-foot" v-if="$slots.foot"><slot name="foot" /></div>
    </div>
  </div>
</template>
