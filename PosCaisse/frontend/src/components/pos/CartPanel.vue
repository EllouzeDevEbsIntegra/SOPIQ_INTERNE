<script setup>
import { computed } from 'vue'
import { useCartStore } from '../../stores/cart'
import { useAuthStore } from '../../stores/auth'
import { useCatalogStore } from '../../stores/catalog'
import { fmt, fmtQty } from '../../utils/money'
import { serviceModeLabel } from '../../utils/i18n'
import Icon from '../common/Icon.vue'

const cart = useCartStore()
const auth = useAuthStore()
const catalog = useCatalogStore()
const emit = defineEmits(['edit', 'discount', 'quantity', 'checkout', 'hold', 'clear', 'customer', 'price', 'note'])

const canDelete = computed(() => auth.can('LINE_DELETE'))
const modes = computed(() => catalog.serviceModes)
const modeIcon = { DINE_IN: 'utensils', TAKEAWAY: 'bag', DELIVERY: 'truck' }
const hasDiscount = computed(() => cart.lineDiscountTotal > 0 || cart.orderDiscount > 0)
</script>

<template>
  <aside class="cart">
    <!-- mode de service : segmenté, toujours visible, une touche pour changer -->
    <div class="modes" v-if="modes.length > 1">
      <button v-for="m in modes" :key="m" class="mode" :class="{ on: cart.serviceMode === m }" @click="cart.serviceMode = m">
        <Icon :name="modeIcon[m]" :size="17" />
        <span>{{ serviceModeLabel(m) }}</span>
      </button>
    </div>

    <button class="customer" @click="emit('customer')">
      <Icon name="user" :size="17" />
      <span v-if="cart.customer.name" class="truncate grow">{{ cart.customer.name }}<span v-if="cart.customer.phone" class="muted"> · {{ cart.customer.phone }}</span></span>
      <span v-else class="muted grow">Client (facultatif)</span>
      <span v-if="cart.heldRef" class="badge warning">{{ cart.heldRef }}</span>
    </button>

    <div class="lines scroll">
      <div v-if="cart.isEmpty" class="blank">
        <Icon name="cart" :size="34" :stroke="1.4" />
        <p>Touchez un produit<br />pour démarrer la commande</p>
      </div>

      <article v-for="l in cart.lines" :key="l.key" class="line" :class="{ on: cart.selectedKey === l.key }" @click="cart.selectedKey = l.key">
        <div class="head">
          <span class="qty num">{{ fmtQty(l.quantity) }}</span>
          <span class="label">{{ l.product.name }}</span>
          <span class="amount num">{{ fmt(cart.lineTotal(l)) }}</span>
        </div>

        <div class="meta" v-if="l.components?.length || l.modifiers?.length || l.note || l.discountAmount || l.discountPercent || l.unitPrice !== Number(l.product.price)">
          <span v-for="c in l.components" :key="'c' + c.productId" class="bit">
            {{ c.quantity > 1 ? c.quantity + '× ' : '' }}{{ c.product?.name }}<template v-if="c.modifiers?.length"> ({{ c.modifiers.map(m => m.name).join(', ') }})</template>
          </span>
          <span v-for="m in l.modifiers" :key="m.id" class="bit">{{ m.name }}<template v-if="m.priceDelta"> +{{ fmt(m.priceDelta) }}</template></span>
          <span v-if="l.unitPrice !== Number(l.product.price)" class="bit alert">Prix {{ fmt(l.unitPrice) }}</span>
          <span v-if="l.discountAmount || l.discountPercent" class="bit alert">Remise −{{ fmt(cart.lineDiscount(l)) }}</span>
          <span v-if="l.note" class="bit quote">{{ l.note }}</span>
        </div>

        <div class="acts" v-if="cart.selectedKey === l.key" @click.stop>
          <div class="step">
            <button @click="cart.increment(l.key, -1)" :disabled="l.quantity <= 1 && !canDelete" aria-label="Diminuer"><Icon name="minus" :size="18" :stroke="2.2" /></button>
            <button class="val num" @click="emit('quantity', l)">{{ fmtQty(l.quantity) }}</button>
            <button @click="cart.increment(l.key, 1)" aria-label="Augmenter"><Icon name="plus" :size="18" :stroke="2.2" /></button>
          </div>
          <button class="act" v-if="l.product.modifierGroups?.length || l.product.productType === 'MENU'" @click="emit('edit', l)"><Icon name="sliders" :size="16" />Options</button>
          <button class="act" v-if="auth.can('DISCOUNT_APPLY')" @click="emit('discount', l)"><Icon name="percent" :size="16" />Remise</button>
          <button class="act" v-if="auth.can('PRICE_EDIT')" @click="emit('price', l)"><Icon name="tag" :size="16" />Prix</button>
          <button class="act" @click="emit('note', l)"><Icon name="note" :size="16" />Note</button>
          <button class="act del" v-if="canDelete" @click="cart.remove(l.key)"><Icon name="trash" :size="16" />Retirer</button>
        </div>
      </article>
    </div>

    <div class="sum">
      <div v-if="hasDiscount" class="line-sum"><span>Sous-total</span><span class="num">{{ fmt(cart.subtotal) }}</span></div>
      <div v-if="cart.lineDiscountTotal" class="line-sum neg"><span>Remises lignes</span><span class="num">−{{ fmt(cart.lineDiscountTotal) }}</span></div>
      <button class="line-sum act-sum" :class="{ neg: cart.orderDiscount > 0 }" :disabled="!auth.can('DISCOUNT_APPLY')" @click="emit('discount', null)">
        <span>Remise commande<template v-if="cart.discountPercent"> · {{ cart.discountPercent }} %</template></span>
        <span class="num">{{ cart.orderDiscount ? '−' + fmt(cart.orderDiscount) : '—' }}</span>
      </button>
      <div class="total">
        <span>Total<span class="items num"> · {{ cart.itemCount }} art.</span></span>
        <b class="num">{{ fmt(cart.total, true) }}</b>
      </div>
    </div>

    <div class="cta">
      <div class="secondary">
        <button class="btn" :disabled="cart.isEmpty" @click="emit('hold')"><Icon name="pause" :size="17" />Attente</button>
        <button class="btn danger" :disabled="cart.isEmpty" @click="emit('clear')"><Icon name="trash" :size="17" />Vider</button>
      </div>
      <button class="pay" :disabled="cart.isEmpty" @click="emit('checkout')">
        <span>Encaisser</span>
        <b class="num">{{ fmt(cart.total, true) }}</b>
      </button>
    </div>
  </aside>
</template>

<style scoped>
.cart { display: flex; flex-direction: column; min-height: 0; background: var(--surface); border-left: 1px solid var(--line); }

.modes { display: flex; gap: 2px; padding: 8px 8px 0; }
.mode {
  flex: 1; display: flex; flex-direction: column; align-items: center; gap: 3px;
  padding: 7px 4px; border-radius: var(--r-sm); color: var(--ink-3);
  font-size: 11.5px; font-weight: 650; letter-spacing: -.005em;
}
.mode:hover { background: var(--surface-2); color: var(--ink-2); }
.mode.on { background: var(--ink); color: #fff; }

.customer {
  display: flex; align-items: center; gap: 9px; margin: 8px; padding: 0 12px; min-height: 42px;
  border: 1px dashed var(--line-2); border-radius: var(--r-sm); color: var(--ink-2); font-size: 14px; font-weight: 550; text-align: left;
}
.customer:hover { border-color: var(--ink-4); background: var(--surface-2); }

.lines { flex: 1; min-height: 0; padding: 0 8px 8px; }
.blank { height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px; color: var(--ink-4); text-align: center; }
.blank p { margin: 0; font-size: 14px; line-height: 1.5; }

.line { padding: 9px 10px; border-radius: var(--r-sm); border: 1px solid transparent; cursor: pointer; }
.line + .line { margin-top: 2px; }
.line:hover { background: var(--surface-2); }
.line.on { background: var(--brand-soft); border-color: var(--brand-line); }

.head { display: grid; grid-template-columns: auto 1fr auto; align-items: baseline; gap: 9px; }
.qty {
  min-width: 24px; padding: 1px 5px; border-radius: var(--r-xs); text-align: center;
  background: var(--surface-3); color: var(--ink-2); font-size: 13px; font-weight: 700;
}
.line.on .qty { background: var(--brand); color: #fff; }
.label { font-size: 14.5px; font-weight: 600; letter-spacing: -.01em; }
.amount { font-size: 14.5px; font-weight: 700; white-space: nowrap; }

.meta { display: flex; flex-wrap: wrap; gap: 3px 8px; margin: 3px 0 0 33px; }
.bit { font-size: 12.5px; color: var(--ink-3); }
.bit::before { content: '+ '; color: var(--ink-4); }
.bit.alert { color: var(--warn); font-weight: 600; }
.bit.alert::before { content: ''; }
.bit.quote { font-style: italic; }
.bit.quote::before { content: '» '; }

.acts { display: flex; flex-wrap: wrap; gap: 5px; margin-top: 9px; }
.step { display: flex; align-items: stretch; border: 1px solid var(--line-2); border-radius: var(--r-sm); overflow: hidden; background: var(--surface); }
.step button { width: 42px; min-height: 40px; display: flex; align-items: center; justify-content: center; color: var(--ink-2); }
.step button:hover:not(:disabled) { background: var(--surface-3); }
.step .val { width: auto; min-width: 46px; font-weight: 700; font-size: 15px; border-left: 1px solid var(--line); border-right: 1px solid var(--line); }
.act {
  display: inline-flex; align-items: center; gap: 6px; min-height: 40px; padding: 0 11px;
  background: var(--surface); border: 1px solid var(--line-2); border-radius: var(--r-sm);
  font-size: 13.5px; font-weight: 600; color: var(--ink-2);
}
.act:hover { background: var(--surface-3); color: var(--ink); }
.act.del { color: var(--danger); border-color: var(--danger-line); background: var(--danger-soft); }

.sum { padding: 11px 14px 12px; border-top: 1px solid var(--line); background: var(--surface-2); }
.line-sum { display: flex; justify-content: space-between; align-items: center; width: 100%; font-size: 13.5px; color: var(--ink-3); padding: 3px 0; }
.line-sum.neg { color: var(--warn); font-weight: 600; }
.act-sum { text-align: left; border-radius: var(--r-xs); }
.act-sum:not(:disabled):hover { color: var(--ink); }
.total { display: flex; justify-content: space-between; align-items: baseline; gap: 10px; margin-top: 7px; padding-top: 9px; border-top: 1px solid var(--line); }
.total > span { font-size: 14px; font-weight: 650; color: var(--ink-2); text-transform: uppercase; letter-spacing: .05em; }
.total .items { color: var(--ink-4); font-weight: 550; letter-spacing: 0; text-transform: none; }
.total b { font-family: var(--font-display); font-size: 30px; font-weight: 750; letter-spacing: -.03em; }

.cta { padding: 10px 12px 12px; border-top: 1px solid var(--line); display: flex; flex-direction: column; gap: 8px; }
.secondary { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.pay {
  display: flex; align-items: center; justify-content: space-between; gap: 12px;
  min-height: 72px; padding: 0 20px; border-radius: var(--r-lg);
  background: var(--pay); color: #fff; box-shadow: 0 4px 14px -4px rgba(21, 120, 74, .6);
  transition: background .12s, transform .06s, box-shadow .12s;
}
.pay span { font-family: var(--font-display); font-size: 19px; font-weight: 650; letter-spacing: .01em; }
.pay b { font-family: var(--font-display); font-size: 25px; font-weight: 750; letter-spacing: -.025em; }
.pay:hover:not(:disabled) { background: var(--pay-2); }
.pay:active:not(:disabled) { transform: translateY(1px); box-shadow: none; }
.pay:disabled { background: var(--line); color: var(--ink-4); box-shadow: none; }

@media (max-height: 720px) {
  .pay { min-height: 60px; } .pay b { font-size: 22px; } .pay span { font-size: 17px; }
  .total b { font-size: 26px; }
}
</style>
