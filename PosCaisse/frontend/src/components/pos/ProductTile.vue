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
    '--c-pic': `rgba(${r},${g},${b},.13)`      /* fond de la vignette */
  }
})
const hasOptions = computed(() => (props.product.modifierGroups || []).length > 0)
/* La vignette est toujours présente, avec ou sans photo : sans image elle porte
   l'initiale dans la teinte de la catégorie, pour qu'une carte partiellement
   illustrée garde une grille régulière. */
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
    <span class="pic">
      <img v-if="showImages && product.imageUrl" :src="product.imageUrl" alt="" draggable="false" />
      <span v-else class="letter">{{ initial }}</span>
    </span>
    <span class="body">
      <span class="top">
        <span class="cat">{{ product.categoryName }}</span>
        <span v-if="product.productType === 'MENU'" class="flag">Menu</span>
        <Icon v-else-if="hasOptions" name="plus" :size="13" :stroke="2.4" class="opt" />
        <span class="price num">{{ fmt(product.price) }}</span>
      </span>
      <span class="rule"></span>
      <span class="name">{{ product.name }}</span>
    </span>
    <span v-if="!product.available" class="veil">Indisponible</span>
  </button>
</template>

<style scoped>
/* Bouton horizontal : vignette à gauche sur toute la hauteur, puis une colonne
   avec le prix aligné à droite et le libellé de l'article en dessous. */
.tile {
  position: relative; display: grid; grid-template-columns: auto minmax(0, 1fr);
  gap: 10px; padding: 8px 10px 8px 8px; text-align: left; overflow: hidden;
  background: var(--c-bg); border: 1px solid var(--c-line); border-radius: var(--r);
  transition: background .1s ease, transform .06s ease, box-shadow .1s ease;
}
.tile::before {                       /* filet de catégorie, discret mais identifiant */
  content: ''; position: absolute; inset: 0 auto 0 0; width: 3px; background: var(--c);
}
.tile:hover { background: #fff; box-shadow: var(--shadow-1); }
.tile:active { background: var(--c-bg-press); transform: translateY(1px); box-shadow: none; }

/* vignette — carrée, calée sur la hauteur de la tuile */
.pic {
  align-self: stretch; aspect-ratio: 1; overflow: hidden;
  display: grid; place-items: center; border-radius: var(--r-sm);
  background: var(--c-pic); border: 1px solid var(--c-line);
}
.pic img { width: 100%; height: 100%; object-fit: cover; display: block; pointer-events: none; }
.letter { font-family: var(--font-display); font-size: 19px; font-weight: 700; color: var(--c); }

.body { display: flex; flex-direction: column; gap: 5px; min-width: 0; }
/* le prix est poussé à droite ; la catégorie et l'indicateur d'options
   restent à gauche de la ligne. La catégorie se tronque avant le prix :
   c'est le prix qui doit rester entier, jamais l'inverse. */
.top { display: flex; align-items: center; gap: 6px; }
.cat {
  min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  font-size: 10px; font-weight: 800; letter-spacing: .08em; text-transform: uppercase;
  color: var(--c); opacity: .85;
}
.price { margin-left: auto; flex: none; font-size: 16.5px; font-weight: 750; color: var(--ink); letter-spacing: -.02em; }
.flag {
  font-size: 9.5px; font-weight: 800; letter-spacing: .1em; text-transform: uppercase;
  color: #fff; background: var(--c); padding: 2px 6px; border-radius: 3px;
}
.opt { color: var(--c); opacity: .8; }

.rule { height: 1px; background: var(--c-line); }

.name {
  flex: 1; min-width: 0;
  font-size: 13.5px; font-weight: 600; line-height: 1.22; letter-spacing: -.01em; color: var(--ink);
  display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden;
}

.tile.S { gap: 8px; padding: 7px 8px 7px 7px; }
.tile.S .price { font-size: 14.5px; }
.tile.S .cat { font-size: 9px; }
.tile.S .letter { font-size: 15px; }
.tile.S .name { font-size: 12.5px; -webkit-line-clamp: 2; }
.tile.L { gap: 12px; padding: 10px 13px 10px 10px; }
.tile.L .price { font-size: 19.5px; }
.tile.L .cat { font-size: 11px; }
.tile.L .letter { font-size: 24px; }
.tile.L .name { font-size: 15px; }

.tile.off { background: var(--surface-2); border-color: var(--line); }
.tile.off .name, .tile.off .price { color: var(--ink-4); }
.tile.off .cat { color: var(--ink-4); }
.tile.off .pic { background: var(--surface-3); border-color: var(--line); }
.tile.off .letter { color: var(--ink-4); }
.tile.off::before { background: var(--line-2); }
.veil {
  position: absolute; inset: auto 0 0 0; padding: 3px 0; text-align: center;
  font-size: 10px; font-weight: 800; letter-spacing: .1em; text-transform: uppercase;
  color: #fff; background: var(--ink-4);
}
</style>
