<script setup>
/** Encaissement tactile : espèces, carte, mixte, rendu de monnaie instantané. */
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import Modal from '../common/Modal.vue'
import NumPad from '../common/NumPad.vue'
import Icon from '../common/Icon.vue'
import { useCatalogStore } from '../../stores/catalog'
import { useCartStore } from '../../stores/cart'
import { fmt, fmtQty, add, sub, mul, round, parseAmount } from '../../utils/money'

const props = defineProps({ total: Number, busy: Boolean })
const emit = defineEmits(['close', 'confirm', 'customer', 'courier'])
const catalog = useCatalogStore()
const cart = useCartStore()

const METHOD_ICON = { CASH: 'cash', CARD: 'card', CHECK: 'receipt', MEAL_VOUCHER: 'tag', CREDIT: 'user', OTHER: 'coins' }
/* Le crédit porte le ticket au compte d'un client : sans client désigné, ce serait
   une dette sans débiteur, donc le moyen reste masqué tant qu'aucun n'est choisi. */
/* Le credit porte la dette sur un compte : il n'apparait donc que si un titulaire est
   choisi. En livraison c'est le livreur qui la porte, puisque c'est lui qui detient
   l'argent jusqu'au versement ; a emporter, c'est le client. */
const holder = computed(() => cart.canPickCourier ? cart.courier : cart.customer)
const methods = computed(() => catalog.paymentMethods.filter(m => m.kind !== 'CREDIT' || !!holder.value?.id))
const customer = computed(() => cart.customer)
const current = ref(methods.value.find(m => m.kind === 'CASH') || methods.value[0])
const entry = ref('')
const payments = ref([])

const paid = computed(() => payments.value.reduce((s, p) => add(s, p.amount), 0))
const remaining = computed(() => Math.max(0, sub(props.total, paid.value)))
const entryValue = computed(() => parseAmount(entry.value))
const isCash = computed(() => current.value?.kind === 'CASH')
const changePreview = computed(() => isCash.value && entryValue.value > remaining.value ? sub(entryValue.value, remaining.value) : 0)
const change = computed(() => payments.value.reduce((s, p) => add(s, p.tendered > p.amount ? sub(p.tendered, p.amount) : 0), 0))
const tendered = computed(() => payments.value.reduce((s, p) => add(s, p.tendered ?? p.amount), 0))
const done = computed(() => remaining.value <= 0 && payments.value.length > 0)
const quick = computed(() => catalog.quickCash)

function pick(m) { current.value = m; entry.value = '' }
/* Si le client est retiré alors que le crédit était sélectionné, on retombe sur
   les espèces : sinon le moyen courant pointerait sur un bouton disparu. */
watch(methods, (list) => {
  if (!list.some(m => m.id === current.value?.id)) current.value = list.find(m => m.kind === 'CASH') || list[0]
})
function addPayment(amountGiven) {
  const given = amountGiven ?? entryValue.value
  if (given <= 0 || remaining.value <= 0) return
  const applied = Math.min(given, remaining.value)
  payments.value.push({ method: current.value, amount: round(applied), tendered: isCash.value ? round(given) : round(applied) })
  entry.value = ''
}
const exact = () => addPayment(remaining.value)
const removePayment = (i) => payments.value.splice(i, 1)

function confirm() {
  if (!done.value || props.busy) return
  emit('confirm', payments.value.map(p => ({
    paymentMethodId: p.method.id,
    amount: p.amount,
    tendered: p.method.kind === 'CASH' ? p.tendered : null
  })))
}
function onKey(e) { if (e.key === 'Enter' && done.value && !props.busy) { e.preventDefault(); confirm() } }
onMounted(() => window.addEventListener('keydown', onKey))
onUnmounted(() => window.removeEventListener('keydown', onKey))
</script>

<template>
  <Modal size="lg" title="Encaissement" :closable="!busy" @close="!busy && emit('close')">
    <div class="pay-grid">
      <!-- colonne gauche : client, articles, montants et moyens -->
      <section class="left">
        <button v-if="cart.canPickCourier" class="customer" :class="{ set: cart.courier?.id }" @click="emit('courier')">
          <Icon name="truck" :size="18" />
          <span class="grow" v-if="cart.courier?.name">Livreur : {{ cart.courier.name }}</span>
          <span class="grow muted" v-else>Aucun livreur — obligatoire en livraison</span>
          <em class="act">{{ cart.courier?.id ? 'Changer' : 'Choisir' }}</em>
        </button>

        <button v-if="cart.canPickCustomer" class="customer" :class="{ set: customer?.id }" @click="emit('customer')">
          <Icon name="user" :size="18" />
          <span class="grow" v-if="customer?.name">{{ customer.name }}<em v-if="customer.phone"> · {{ customer.phone }}</em></span>
          <span class="grow muted" v-else>Aucun client{{ cart.canPickCourier ? '' : ' — nécessaire pour le crédit' }}</span>
          <em class="act">{{ customer?.id ? 'Changer' : 'Choisir' }}</em>
        </button>

        <details class="basket" open>
          <summary>{{ cart.itemCount }} article{{ cart.itemCount > 1 ? 's' : '' }} au panier</summary>
          <ul>
            <li v-for="l in cart.lines" :key="l.key">
              <b class="q num">{{ fmtQty(l.quantity) }}</b>
              <span class="n">{{ l.product.name }}
                <em v-if="l.modifiers?.length">{{ l.modifiers.map(m => ((m.quantity || 1) > 1 ? m.quantity + ' × ' : '') + m.name).join(', ') }}</em>
              </span>
              <b class="a num">{{ fmt(mul(l.unitPrice, l.quantity)) }}</b>
            </li>
          </ul>
        </details>

        <div class="board">
          <div class="row-amount">
            <span>À payer</span>
            <b class="num">{{ fmt(total, true) }}</b>
          </div>
          <div class="row-amount sub" v-if="payments.length">
            <span>Reçu</span>
            <b class="num">{{ fmt(tendered) }}</b>
          </div>
          <div class="row-amount main" :class="remaining > 0 ? 'due' : 'ok'">
            <span>{{ remaining > 0 ? 'Reste à payer' : 'Monnaie à rendre' }}</span>
            <b class="num">{{ fmt(remaining > 0 ? remaining : change, true) }}</b>
          </div>
        </div>

        <div class="methods">
          <button v-for="m in methods" :key="m.id" class="method" :class="{ on: current?.id === m.id }" @click="pick(m)">
            <Icon :name="METHOD_ICON[m.kind] || 'coins'" :size="19" />
            <span>{{ m.name }}</span>
          </button>
        </div>

        <div class="quick" v-if="isCash">
          <button v-for="q in quick" :key="q" class="chip num" :disabled="remaining <= 0" @click="addPayment(q)">
            {{ q }} {{ catalog.company?.currencySymbol || 'DT' }}
          </button>
          <button class="chip exact" :disabled="remaining <= 0" @click="exact">
            Montant exact <b class="num">{{ fmt(remaining) }}</b>
          </button>
        </div>
        <button v-else class="chip exact solo" :disabled="remaining <= 0" @click="exact">
          {{ current?.name }} <b class="num">{{ fmt(remaining) }}</b>
        </button>

        <ul class="ledger" v-if="payments.length">
          <li v-for="(p, i) in payments" :key="i">
            <Icon :name="METHOD_ICON[p.method.kind] || 'coins'" :size="16" />
            <span class="grow">
              {{ p.method.name }}
              <em v-if="p.tendered > p.amount" class="tiny muted">reçu {{ fmt(p.tendered) }} · rendu {{ fmt(sub(p.tendered, p.amount)) }}</em>
            </span>
            <b class="num">{{ fmt(p.amount) }}</b>
            <button class="drop" @click="removePayment(i)" aria-label="Retirer"><Icon name="close" :size="15" :stroke="2.2" /></button>
          </li>
        </ul>
      </section>

      <!-- colonne droite : saisie -->
      <section class="right">
        <NumPad v-model="entry" mode="amount" :ok-label="isCash ? 'Reçu' : 'Ajouter'" :placeholder="fmt(remaining)" @ok="addPayment()" />

        <p class="change" v-if="changePreview">Monnaie à rendre <b class="num">{{ fmt(changePreview, true) }}</b></p>
      </section>
    </div>

    <template #foot>
      <button class="btn lg" :disabled="busy" @click="emit('close')">Annuler</button>
      <button class="btn success xl grow" :disabled="!done || busy" @click="confirm">
        {{ busy ? 'Enregistrement…' : 'Valider le paiement' }}
      </button>
    </template>
  </Modal>
</template>

<style scoped>
.pay-grid { display: grid; grid-template-columns: minmax(0, 1fr) 316px; gap: 20px; align-items: start; }

/* --- client --- */
.customer {
  display: flex; align-items: center; gap: 10px; width: 100%; min-height: 46px; margin-bottom: 10px;
  padding: 0 13px; border: 1px dashed var(--line-2); border-radius: var(--r);
  font-size: 14px; font-weight: 600; color: var(--ink-2); text-align: left;
}
.customer:hover { border-color: var(--brand); color: var(--ink); }
.customer.set { border-style: solid; border-color: var(--brand-line); background: var(--brand-soft); color: var(--ink); }
.customer em { font-style: normal; font-weight: 500; color: var(--ink-3); }
.customer .act { font-size: 12px; font-weight: 700; color: var(--brand); }

/* --- rappel du panier --- */
.basket { margin-bottom: 12px; border: 1px solid var(--line); border-radius: var(--r); background: var(--surface-2); }
.basket summary {
  padding: 9px 13px; cursor: pointer; list-style: none;
  font-size: 12px; font-weight: 750; letter-spacing: .07em; text-transform: uppercase; color: var(--ink-3);
}
.basket summary::-webkit-details-marker { display: none; }
.basket ul { max-height: 168px; overflow: auto; margin: 0; padding: 0 4px 6px; list-style: none; }
.basket li { display: grid; grid-template-columns: 34px minmax(0, 1fr) auto; gap: 9px; align-items: baseline;
  padding: 5px 9px; border-top: 1px solid var(--line); }
.basket .q { font-size: 13px; font-weight: 700; color: var(--ink-3); }
.basket .n { font-size: 13.5px; font-weight: 600; line-height: 1.25; }
.basket .n em { display: block; font-style: normal; font-size: 11.5px; font-weight: 500; color: var(--ink-3); }
.basket .a { font-size: 13.5px; font-weight: 700; }

/* --- montants --- */
.board { background: var(--ink); border-radius: var(--r-lg); padding: 14px 18px 16px; color: #E8E2DA; }
.row-amount { display: flex; align-items: baseline; justify-content: space-between; gap: 14px; padding: 3px 0; }
.row-amount > span { font-size: 13px; font-weight: 550; color: #A69C90; }
.row-amount b { font-family: var(--font-display); font-size: 21px; font-weight: 700; letter-spacing: -.02em; color: #fff; }
.row-amount.sub b { font-size: 17px; color: #C9C0B6; }
.row-amount.main { margin-top: 9px; padding-top: 11px; border-top: 1px solid rgba(255, 255, 255, .14); align-items: center; }
.row-amount.main > span { font-size: 12px; font-weight: 700; letter-spacing: .08em; text-transform: uppercase; }
.row-amount.main b { font-size: 34px; letter-spacing: -.03em; }
.row-amount.due > span { color: #F0B49A; } .row-amount.due b { color: #FF9B6A; }
.row-amount.ok > span { color: #9AD9B6; } .row-amount.ok b { color: #6FE0A6; }

/* --- moyens de paiement --- */
.methods { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 8px; margin-top: 12px; }
.method {
  display: flex; align-items: center; gap: 9px; min-height: 54px; padding: 0 14px;
  border: 1px solid var(--line-2); border-radius: var(--r); background: var(--surface);
  font-size: 14.5px; font-weight: 600; color: var(--ink-2); text-align: left;
}
.method:hover { background: var(--surface-2); }
.method.on { background: var(--ink); border-color: var(--ink); color: #fff; }

/* --- paiements enregistrés --- */
.ledger { list-style: none; margin: 12px 0 0; padding: 0; border: 1px solid var(--line); border-radius: var(--r); overflow: hidden; }
.ledger li { display: flex; align-items: center; gap: 10px; padding: 10px 12px; color: var(--ink-2); }
.ledger li + li { border-top: 1px solid var(--surface-3); }
.ledger li span { display: flex; flex-direction: column; font-size: 14px; font-weight: 600; }
.ledger li em { font-style: normal; font-weight: 500; }
.ledger li b { font-size: 15px; font-weight: 700; }
.drop { display: flex; padding: 6px; border-radius: var(--r-xs); color: var(--ink-3); }
.drop:hover { background: var(--danger-soft); color: var(--danger); }

/* --- saisie --- */
.right { display: flex; flex-direction: column; gap: 10px; }
.quick { display: grid; grid-template-columns: repeat(4, 1fr); gap: 7px; margin-top: 12px; }
.chip {
  min-height: 46px; padding: 0 10px; border-radius: var(--r-sm);
  border: 1px solid var(--line-2); background: var(--surface);
  font-size: 15px; font-weight: 650; color: var(--ink);
}
.chip:hover:not(:disabled) { background: var(--surface-2); }
.chip.exact {
  grid-column: 1 / -1; display: flex; align-items: center; justify-content: space-between;
  background: var(--brand); border-color: var(--brand); color: #fff; font-size: 15px;
}
.chip.exact:hover:not(:disabled) { background: var(--brand-2); }
.chip.exact b { font-size: 17px; font-weight: 750; }
.chip.exact.solo { width: 100%; }
.change { margin: 0; text-align: right; font-size: 14px; color: var(--pay-2); }
.change b { font-family: var(--font-display); font-size: 19px; margin-left: 6px; }

@media (max-width: 880px) {
  .pay-grid { grid-template-columns: 1fr; }
  .quick { grid-template-columns: repeat(4, 1fr); }
}
</style>
