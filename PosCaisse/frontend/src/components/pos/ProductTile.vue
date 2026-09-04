<script setup>
import { fmt } from '../../utils/money'
defineProps({ product: Object, size: { type: String, default: 'M' }, showImages: { type: Boolean, default: true } })
const emit = defineEmits(['tap', 'hold'])
let timer = null
function down() { timer = setTimeout(() => { timer = null; emit('hold') }, 650) }
function up() { if (timer) { clearTimeout(timer); timer = null; emit('tap') } }
function cancel() { if (timer) { clearTimeout(timer); timer = null } }
</script>
<template>
  <button class="tile" :class="[size, { off: !product.available, menu: product.productType==='MENU' }]" :style="{ '--c': product.color || '#3b82f6' }"
          @pointerdown.prevent="down" @pointerup.prevent="up" @pointerleave="cancel" @pointercancel="cancel" @contextmenu.prevent>
    <img v-if="showImages && product.imageUrl" :src="product.imageUrl" alt="" class="img" draggable="false" />
    <span class="name">{{ product.name }}</span>
    <span class="price num">{{ fmt(product.price) }}</span>
    <span v-if="!product.available" class="off-label">INDISPONIBLE</span>
    <span v-else-if="product.productType==='MENU'" class="tag">MENU</span>
    <span v-else-if="product.modifierGroups?.length" class="tag dot">+</span>
  </button>
</template>
<style scoped>
.tile { position: relative; display: flex; flex-direction: column; justify-content: space-between; align-items: flex-start; gap: 4px; padding: 10px 12px; border-radius: 14px; background: #fff; border-left: 7px solid var(--c); box-shadow: var(--shadow); text-align: left; min-height: 96px; overflow: hidden; transition: transform .06s; }
.tile.S { min-height: 76px; padding: 8px 10px; } .tile.L { min-height: 124px; }
.tile:active { transform: scale(.96); background: color-mix(in srgb, var(--c) 12%, #fff); }
.name { font-weight: 700; font-size: 15px; line-height: 1.2; overflow: hidden; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; }
.tile.L .name { font-size: 17px; } .tile.S .name { font-size: 14px; -webkit-line-clamp: 1; }
.price { font-weight: 800; font-size: 15px; color: var(--c); }
.img { width: 100%; height: 56px; object-fit: cover; border-radius: 8px; pointer-events: none; }
.tile.S .img { display: none; }
.tile.off { opacity: .55; background: repeating-linear-gradient(45deg, #fff, #fff 8px, #f1f5f9 8px, #f1f5f9 16px); }
.off-label { position: absolute; right: 8px; top: 8px; font-size: 10px; font-weight: 800; color: var(--danger); background: var(--danger-soft); padding: 2px 6px; border-radius: 6px; letter-spacing: .05em; }
.tag { position: absolute; right: 8px; top: 8px; font-size: 10px; font-weight: 800; color: #fff; background: var(--c); padding: 2px 6px; border-radius: 6px; letter-spacing: .05em; }
.tag.dot { border-radius: 50%; width: 20px; height: 20px; display: flex; align-items: center; justify-content: center; padding: 0; font-size: 14px; }
</style>
