<script setup>
import { computed } from 'vue'
import { fmt } from '../../utils/money'
import Icon from '../common/Icon.vue'

const props = defineProps({
  product: Object,
  size: { type: String, default: 'M' },
  showImages: { type: Boolean, default: true }
})
const emit = defineEmits(['tap', 'hold'])

/* La teinte de catégorie est calculée en JS : rendu identique sur tous les moteurs,
   sans dépendre de color-mix(). */
function rgb(hex) {
  const h = (hex || '#8A8178').replace('#', '')
  const v = h.length === 3 ? h.split('').map(c => c + c).join('') : h
  const n = parseInt(v, 16)
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255]
}
const tint = computed(() => {
  const [r, g, b] = rgb(props.product.color)
  return {
    '--c': props.product.color || '#8A8178',
    '--c-bg': `rgba(${r},${g},${b},.055)`,
    '--c-bg-press': `rgba(${r},${g},${b},.16)`,
    '--c-line': `rgba(${r},${g},${b},.28)`
  }
})
const hasOptions = computed(() => (props.product.modifierGroups || []).length > 0)

let timer = null
function down() { timer = setTimeout(() => { timer = null; emit('hold') }, 600) }
function up() { if (timer) { clearTimeout(timer); timer = null; emit('tap') } }
function cancel() { if (timer) { clearTimeout(timer); timer = null } }
</script>

<template>
  <button
    class="tile" :class="[size, { off: !product.available }]" :style="tint"
    @pointerdown.prevent="down" @pointerup.prevent="up" @pointerleave="cancel" @pointercancel="cancel" @contextmenu.prevent>
    <img v-if="showImages && product.imageUrl" :src="product.imageUrl" alt="" class="thumb" draggable="false" />
    <span class="name">{{ product.name }}</span>
    <span class="foot">
      <span class="price num">{{ fmt(product.price) }}</span>
      <span v-if="product.productType === 'MENU'" class="flag">Menu</span>
      <Icon v-else-if="hasOptions" name="plus" :size="14" :stroke="2.4" class="opt" />
    </span>
    <span v-if="!product.available" class="veil">Indisponible</span>
  </button>
</template>

<style scoped>
.tile {
  position: relative; display: flex; flex-direction: column; justify-content: space-between; gap: 6px;
  padding: 11px 12px; text-align: left; overflow: hidden;
  background: var(--c-bg); border: 1px solid var(--c-line); border-radius: var(--r);
  transition: background .1s ease, transform .06s ease, box-shadow .1s ease;
}
.tile::before {                       /* filet de catégorie, discret mais identifiant */
  content: ''; position: absolute; inset: 0 auto 0 0; width: 3px; background: var(--c);
}
.tile:hover { background: #fff; box-shadow: var(--shadow-1); }
.tile:active { background: var(--c-bg-press); transform: translateY(1px); box-shadow: none; }

.name {
  font-size: 14.5px; font-weight: 600; line-height: 1.22; letter-spacing: -.01em; color: var(--ink);
  display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden;
}
.foot { display: flex; align-items: center; justify-content: space-between; gap: 6px; }
.price { font-size: 14px; font-weight: 700; color: var(--ink-2); letter-spacing: -.01em; }
.flag {
  font-size: 9.5px; font-weight: 800; letter-spacing: .1em; text-transform: uppercase;
  color: #fff; background: var(--c); padding: 2px 6px; border-radius: 3px;
}
.opt { color: var(--c); opacity: .8; }
.thumb { width: 100%; height: 54px; object-fit: cover; border-radius: var(--r-xs); pointer-events: none; }

.tile.S { padding: 8px 10px; }
.tile.S .name { font-size: 13.5px; -webkit-line-clamp: 2; }
.tile.S .thumb { display: none; }
.tile.L { padding: 14px 15px; }
.tile.L .name { font-size: 16.5px; }
.tile.L .price { font-size: 15.5px; }
.tile.L .thumb { height: 72px; }

.tile.off { background: var(--surface-2); border-color: var(--line); }
.tile.off .name, .tile.off .price { color: var(--ink-4); }
.tile.off::before { background: var(--line-2); }
.veil {
  position: absolute; inset: auto 0 0 0; padding: 3px 0; text-align: center;
  font-size: 10px; font-weight: 800; letter-spacing: .1em; text-transform: uppercase;
  color: #fff; background: var(--ink-4);
}
</style>
