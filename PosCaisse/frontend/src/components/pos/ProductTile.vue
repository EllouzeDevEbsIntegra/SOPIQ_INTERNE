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
    '--c-line': `rgba(${r},${g},${b},.28)`,
    '--c-disc': `rgba(${r},${g},${b},.13)`     /* fond du médaillon */
  }
})
const hasOptions = computed(() => (props.product.modifierGroups || []).length > 0)
/* Le médaillon est toujours présent, avec ou sans photo : la tuile garde la même
   silhouette, et une carte partiellement illustrée ne devient pas bancale. */
const initial = computed(() => (props.product.name || '?').trim().charAt(0).toUpperCase())

let timer = null
function down() { timer = setTimeout(() => { timer = null; emit('hold') }, 600) }
function up() { if (timer) { clearTimeout(timer); timer = null; emit('tap') } }
function cancel() { if (timer) { clearTimeout(timer); timer = null } }
</script>

<template>
  <button
    class="tile" :class="[size, { off: !product.available }]" :style="tint"
    @pointerdown.prevent="down" @pointerup.prevent="up" @pointerleave="cancel" @pointercancel="cancel" @contextmenu.prevent>
    <span class="top">
      <span class="price num">{{ fmt(product.price) }}</span>
      <span class="disc">
        <img v-if="showImages && product.imageUrl" :src="product.imageUrl" alt="" draggable="false" />
        <span v-else class="letter">{{ initial }}</span>
      </span>
    </span>
    <span class="rule"></span>
    <span class="foot">
      <span class="name">{{ product.name }}</span>
      <span v-if="product.productType === 'MENU'" class="flag">Menu</span>
      <Icon v-else-if="hasOptions" name="plus" :size="14" :stroke="2.4" class="opt" />
    </span>
    <span v-if="!product.available" class="veil">Indisponible</span>
  </button>
</template>

<style scoped>
.tile {
  position: relative; display: flex; flex-direction: column; gap: 6px;
  padding: 10px 11px; text-align: left; overflow: hidden;
  background: var(--c-bg); border: 1px solid var(--c-line); border-radius: var(--r);
  transition: background .1s ease, transform .06s ease, box-shadow .1s ease;
}
.tile::before {                       /* filet de catégorie, discret mais identifiant */
  content: ''; position: absolute; inset: 0 auto 0 0; width: 3px; background: var(--c);
}
.tile:hover { background: #fff; box-shadow: var(--shadow-1); }
.tile:active { background: var(--c-bg-press); transform: translateY(1px); box-shadow: none; }

/* ---- ligne haute : prix à gauche, médaillon à droite ---- */
.top { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.price { font-size: 17px; font-weight: 750; color: var(--ink); letter-spacing: -.02em; }
.disc {
  flex: none; width: 40px; height: 40px; border-radius: 50%; overflow: hidden;
  display: grid; place-items: center;
  background: var(--c-disc); border: 1px solid var(--c-line);
}
.disc img { width: 100%; height: 100%; object-fit: cover; display: block; pointer-events: none; }
.letter { font-family: var(--font-display); font-size: 16px; font-weight: 700; color: var(--c); }

.rule { height: 1px; background: var(--c-line); }

/* ---- ligne basse : nom de l'article ---- */
.foot { display: flex; align-items: center; gap: 7px; }
.name {
  flex: 1; min-width: 0;
  font-size: 14px; font-weight: 600; line-height: 1.22; letter-spacing: -.01em; color: var(--ink);
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}
.flag {
  flex: none;
  font-size: 9.5px; font-weight: 800; letter-spacing: .1em; text-transform: uppercase;
  color: #fff; background: var(--c); padding: 2px 6px; border-radius: 3px;
}
.opt { flex: none; color: var(--c); opacity: .8; }

.tile.S { padding: 8px 9px; gap: 5px; }
.tile.S .price { font-size: 15px; }
.tile.S .disc { width: 30px; height: 30px; }
.tile.S .letter { font-size: 13px; }
.tile.S .name { font-size: 13.5px; -webkit-line-clamp: 2; }
.tile.L { padding: 13px 14px; gap: 8px; }
.tile.L .price { font-size: 19.5px; }
.tile.L .disc { width: 52px; height: 52px; }
.tile.L .letter { font-size: 20px; }
.tile.L .name { font-size: 15.5px; }

.tile.off { background: var(--surface-2); border-color: var(--line); }
.tile.off .name, .tile.off .price { color: var(--ink-4); }
.tile.off .disc { background: var(--surface-3); border-color: var(--line); }
.tile.off .letter { color: var(--ink-4); }
.tile.off::before { background: var(--line-2); }
.veil {
  position: absolute; inset: auto 0 0 0; padding: 3px 0; text-align: center;
  font-size: 10px; font-weight: 800; letter-spacing: .1em; text-transform: uppercase;
  color: #fff; background: var(--ink-4);
}
</style>
