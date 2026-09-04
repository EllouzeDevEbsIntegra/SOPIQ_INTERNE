<script setup>
/**
 * Aperçu d'un ticket à l'écran, avec la même mise en forme qu'à l'impression.
 *
 * La largeur est exprimée en caractères (unité ch) et non en pixels : c'est le nombre
 * de colonnes qui définit un ticket, et une largeur fixe en pixels rognait les lignes
 * pleines dès que la police changeait de taille.
 */
import { computed } from 'vue'
import { receiptBlocks } from '../../utils/receipt'
const props = defineProps({
  content: String, logo: String,
  paperWidth: { type: Number, default: 80 },
  fontSize: { type: Number, default: 12 }
})
const blocks = computed(() => receiptBlocks(props.content))
const columns = computed(() => (props.paperWidth <= 58 ? 32 : 42))
</script>
<template>
  <div class="receipt-paper" :style="{ width: `calc(${columns}ch + 18px)`, fontSize: fontSize + 'px' }">
    <img v-if="logo" :src="logo" alt="" class="logo" />
    <pre v-for="(b, i) in blocks" :key="i" :class="{ big: b.big }">{{ b.text }}</pre>
  </div>
</template>
<style scoped>
.logo { max-width: 60%; max-height: 80px; display: block; margin: 0 auto 6px; filter: grayscale(1) contrast(1.3); }
pre { margin: 0; font: inherit; white-space: pre; }
pre.big { font-size: 2em; font-weight: 800; line-height: 1.06; }
</style>
