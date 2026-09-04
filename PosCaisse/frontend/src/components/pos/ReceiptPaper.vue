<script setup>
/**
 * Aperçu d'un ticket à l'écran, avec la même mise en forme qu'à l'impression.
 *
 * La largeur est exprimée en caractères (unité ch) et non en pixels : c'est le nombre
 * de colonnes qui définit un ticket, et une largeur fixe en pixels rognait les lignes
 * pleines dès que la police changeait de taille.
 */
import { computed } from 'vue'
import { headFields, receiptBlocks } from '../../utils/receipt'
const props = defineProps({
  content: String, logo: String,
  paperWidth: { type: Number, default: 80 },
  fontSize: { type: Number, default: 12 }
})
const blocks = computed(() => receiptBlocks(props.content))
const columns = computed(() => (props.paperWidth <= 58 ? 32 : 42))
const rows = (block) => block.lines.map(headFields).filter(p => p.length)
</script>
<template>
  <div class="receipt-paper" :style="{ width: `calc(${columns}ch + 18px)`, fontSize: fontSize + 'px' }">
    <template v-for="(b, i) in blocks" :key="i">
      <div v-if="b.kind === 'head'" class="head">
        <img v-if="logo" :src="logo" alt="" class="logo" />
        <div class="head-txt">
          <div v-for="(parts, j) in rows(b)" :key="j" :class="[j === 0 ? 'name' : 'when', { split: parts.length > 1 }]">
            <span v-for="(p, k) in parts" :key="k">{{ p }}</span>
          </div>
        </div>
      </div>
      <pre v-else :class="{ big: b.kind === 'big' }">{{ b.lines.join('\n') }}</pre>
    </template>
  </div>
</template>
<style scoped>
pre { margin: 0; font: inherit; white-space: pre; }
pre.big { font-size: 2em; font-weight: 800; line-height: 1.06; }

.head { display: flex; align-items: center; gap: 10px; margin-bottom: 5px; }
.head .logo { flex: none; width: 34%; max-height: 62px; object-fit: contain; filter: grayscale(1) contrast(1.35); }
.head-txt { flex: 1; min-width: 0; }
.head .name { font-size: 1.5em; font-weight: 800; line-height: 1.12; text-align: right; letter-spacing: -.01em; }
.head .when { margin-top: 2px; text-align: center; }
.head .split { display: flex; justify-content: space-between; gap: 8px; text-align: left; }
</style>
