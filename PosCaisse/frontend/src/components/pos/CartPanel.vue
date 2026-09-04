<script setup>
import { computed } from 'vue'
import { useCartStore } from '../../stores/cart'
import { useAuthStore } from '../../stores/auth'
import { fmt, fmtQty } from '../../utils/money'
import { serviceModeLabel } from '../../utils/i18n'
const cart = useCartStore(); const auth = useAuthStore()
const emit = defineEmits(['edit', 'discount', 'quantity', 'checkout', 'hold', 'clear', 'customer', 'service', 'price', 'note'])
const canDelete = computed(() => auth.can('LINE_DELETE'))
function select(l) { cart.selectedKey = l.key }
</script>
<template>
  <aside class="cart">
    <div class="cart-head">
      <div class="row between">
        <div><b>Commande</b> <span v-if="cart.heldRef" class="badge warning">Reprise {{ cart.heldRef }}</span></div>
        <button class="btn sm soft" @click="emit('service')">{{ serviceModeLabel(cart.serviceMode) }} ▾</button>
      </div>
      <button class="cust" @click="emit('customer')">
        <span v-if="cart.customer.name">👤 {{ cart.customer.name }} <span class="muted small" v-if="cart.customer.phone">{{ cart.customer.phone }}</span></span>
        <span v-else class="muted">👤 Client (facultatif)</span>
      </button>
    </div>
    <div class="lines scroll">
      <div v-if="cart.isEmpty" class="empty-cart"><div style="font-size:42px">🛒</div><div>Touchez un produit pour l'ajouter</div></div>
      <div v-for="l in cart.lines" :key="l.key" class="line" :class="{ on: cart.selectedKey===l.key }" @click="select(l)">
        <div class="line-main">
          <div class="lname"><span class="q num">{{ fmtQty(l.quantity) }} ×</span> {{ l.product.name }}</div>
          <div class="ltotal num">{{ fmt(cart.lineTotal(l)) }}</div>
        </div>
        <div class="lsub" v-if="l.modifiers?.length || l.components?.length || l.note || l.discountPercent || l.discountAmount || l.unitPrice !== Number(l.product.price)">
          <div v-for="c in l.components" :key="'c'+c.productId" class="sub">• {{ c.quantity > 1 ? c.quantity + ' ' : '' }}{{ c.product?.name }}<span v-if="c.priceDelta" class="delta"> +{{ fmt(c.priceDelta) }}</span><span v-if="c.modifiers?.length"> ({{ c.modifiers.map(m=>m.name).join(', ') }})</span></div>
          <div v-for="m in l.modifiers" :key="m.id" class="sub">+ {{ m.name }}<span v-if="m.priceDelta" class="delta"> +{{ fmt(m.priceDelta) }}</span></div>
          <div v-if="l.unitPrice !== Number(l.product.price)" class="sub warn">Prix modifié : {{ fmt(l.unitPrice) }} (au lieu de {{ fmt(l.product.price) }})</div>
          <div v-if="l.discountAmount || l.discountPercent" class="sub warn">Remise {{ l.discountPercent ? l.discountPercent + ' %' : fmt(l.discountAmount) }} : −{{ fmt(cart.lineDiscount(l)) }}</div>
          <div v-if="l.note" class="sub">» {{ l.note }}</div>
        </div>
        <div class="line-actions" v-if="cart.selectedKey===l.key" @click.stop>
          <button class="btn icon lg" @click="cart.increment(l.key,-1)" :disabled="l.quantity<=1 && !canDelete">−</button>
          <button class="btn lg qbtn num" @click="emit('quantity', l)">{{ fmtQty(l.quantity) }}</button>
          <button class="btn icon lg" @click="cart.increment(l.key,1)">+</button>
          <button class="btn lg" v-if="l.product.modifierGroups?.length || l.product.productType==='MENU'" @click="emit('edit', l)">Options</button>
          <button class="btn lg" v-if="auth.can('DISCOUNT_APPLY')" @click="emit('discount', l)">Remise</button>
          <button class="btn lg" v-if="auth.can('PRICE_EDIT')" @click="emit('price', l)">Prix</button>
          <button class="btn lg" @click="emit('note', l)">Note</button>
          <button class="btn lg danger" v-if="canDelete" @click="cart.remove(l.key)">Supprimer</button>
        </div>
      </div>
    </div>
    <div class="totals">
      <div class="trow" v-if="cart.lineDiscountTotal || cart.orderDiscount"><span>Sous-total</span><span class="num">{{ fmt(cart.subtotal) }}</span></div>
      <div class="trow" v-if="cart.lineDiscountTotal"><span>Remises lignes</span><span class="num">−{{ fmt(cart.lineDiscountTotal) }}</span></div>
      <div class="trow discount" @click="auth.can('DISCOUNT_APPLY') && emit('discount', null)">
        <span>Remise commande <span v-if="cart.discountPercent" class="badge accent">{{ cart.discountPercent }} %</span></span><span class="num">−{{ fmt(cart.orderDiscount) }}</span>
      </div>
      <div class="trow total"><span>TOTAL</span><span class="num">{{ fmt(cart.total, true) }}</span></div>
      <div class="tsub muted small">{{ cart.itemCount }} article(s)</div>
    </div>
    <div class="cart-actions">
      <button class="btn lg" :disabled="cart.isEmpty" @click="emit('hold')">⏸ Attente</button>
      <button class="btn lg danger" :disabled="cart.isEmpty" @click="emit('clear')">✕ Vider</button>
      <button class="btn success xl checkout" :disabled="cart.isEmpty" @click="emit('checkout')">ENCAISSER<span class="num">{{ fmt(cart.total, true) }}</span></button>
    </div>
  </aside>
</template>
<style scoped>
.cart { display: flex; flex-direction: column; background: var(--surface); border-left: 1px solid var(--border); height: 100%; min-height: 0; min-width: 0; }
.cart-head { padding: 10px 12px; border-bottom: 1px solid var(--border); display: flex; flex-direction: column; gap: 8px; }
.cust { text-align: left; min-height: 40px; padding: 6px 10px; border-radius: 10px; background: var(--surface-2); border: 1px dashed var(--border-strong); font-weight: 600; }
.lines { flex: 1; padding: 6px; }
.empty-cart { height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 8px; color: var(--text-3); text-align: center; }
.line { padding: 10px 10px; border-radius: 12px; border: 2px solid transparent; margin-bottom: 4px; background: var(--surface-2); cursor: pointer; }
.line.on { border-color: var(--accent); background: var(--accent-soft); }
.line-main { display: flex; justify-content: space-between; gap: 10px; align-items: baseline; }
.lname { font-weight: 700; font-size: 16px; } .q { color: var(--accent-2); margin-right: 2px; } .ltotal { font-weight: 800; font-size: 16px; white-space: nowrap; }
.lsub { margin-top: 2px; padding-left: 4px; } .sub { font-size: 13px; color: var(--text-2); } .sub.warn { color: #b45309; font-weight: 600; } .delta { color: var(--accent-2); font-weight: 600; }
.line-actions { display: flex; gap: 6px; flex-wrap: wrap; margin-top: 10px; } .qbtn { min-width: 64px; font-weight: 800; }
.totals { padding: 10px 14px; border-top: 1px solid var(--border); }
.trow { display: flex; justify-content: space-between; font-size: 15px; color: var(--text-2); padding: 2px 0; }
.trow.discount { cursor: pointer; }
.trow.total { font-size: 28px; font-weight: 900; color: var(--text); padding-top: 6px; letter-spacing: -.01em; }
.tsub { text-align: right; }
.cart-actions { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; padding: 10px; border-top: 1px solid var(--border); background: var(--surface-2); }
.checkout { grid-column: 1 / -1; min-height: 84px; font-size: 24px; font-weight: 900; display: flex; flex-direction: column; gap: 0; line-height: 1.1; box-shadow: 0 8px 24px rgba(22,163,74,.35); }
.checkout span { font-size: 18px; font-weight: 700; opacity: .95; }
</style>
