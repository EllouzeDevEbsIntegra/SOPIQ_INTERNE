<script setup>
/**
 * Remarques de cuisine sur une ligne du panier.
 *
 * Les remarques courantes se touchent dans une liste tenue au back-office ; tout le reste
 * s'écrit librement. Quand la ligne porte plusieurs unités, l'onglet « Toutes » les traite
 * ensemble — le cas ordinaire — et les onglets numérotés permettent de donner à chacune sa
 * propre consigne : une sans sauce, une sans frites ni harissa, une ordinaire. À la
 * validation, la ligne se scinde en autant de lignes que de consignes distinctes.
 */
import { computed, ref } from 'vue'
import Modal from '../common/Modal.vue'
import Icon from '../common/Icon.vue'
import { useCatalogStore } from '../../stores/catalog'
import { fmtQty } from '../../utils/money'

const props = defineProps({ line: Object })
const emit = defineEmits(['close', 'ok'])
const catalog = useCatalogStore()

const notes = computed(() => catalog.kitchenNotes)
const labels = computed(() => new Set(notes.value.map(n => n.label)))

/* Au-dela de deux douzaines d'unites, les distinguer une a une n'a plus de sens sur un
   ecran tactile ; une quantite fractionnaire (vente au poids) n'a pas d'unites du tout. */
const quantity = Number(props.line?.quantity) || 1
const count = Number.isInteger(quantity) && quantity > 1 && quantity <= 24 ? quantity : 1

/* La note enregistree est un simple texte : on retrouve les remarques connues pour les
   re-cocher, et ce qui n'en fait pas partie retourne dans la saisie libre. */
function parse(text) {
  const parts = String(text || '').split(',').map(t => t.trim()).filter(Boolean)
  return { picked: parts.filter(t => labels.value.has(t)), free: parts.filter(t => !labels.value.has(t)).join(', ') }
}
const units = ref(Array.from({ length: count }, () => parse(props.line?.note)))

const TOUTES = -1
const current = ref(TOUTES)

/** Texte final d'une unite : les remarques dans l'ordre du back-office, puis la saisie libre. */
function text(u) {
  const chosen = notes.value.filter(n => u.picked.includes(n.label)).map(n => n.label)
  return [...chosen, u.free.trim()].filter(Boolean).join(', ')
}
const resumes = computed(() => units.value.map(text))
const identiques = computed(() => resumes.value.every(r => r === resumes.value[0]))

/* L'onglet « Toutes » montre l'etat commun ; si les unites different, il repart de zero et
   le dira, pour qu'on ne les ecrase pas sans le savoir. */
const shown = computed(() => (current.value !== TOUTES ? units.value[current.value]
  : identiques.value ? units.value[0] : { picked: [], free: '' }))

function edit(change) {
  const base = { picked: [...shown.value.picked], free: shown.value.free }
  change(base)
  if (current.value === TOUTES) units.value = units.value.map(() => ({ picked: [...base.picked], free: base.free }))
  else units.value = units.value.map((u, i) => (i === current.value ? base : u))
}
const toggle = (n) => edit(u => {
  const i = u.picked.indexOf(n.label)
  i >= 0 ? u.picked.splice(i, 1) : u.picked.push(n.label)
})
const setFree = (v) => edit(u => { u.free = v })

const validate = () => emit('ok', { notes: resumes.value })
const clear = () => emit('ok', { notes: units.value.map(() => '') })
</script>

<template>
  <Modal size="md" :title="'Remarques — ' + (line.product?.name || '')" @close="emit('close')">
    <div class="col gap-14">
      <!-- Onglets d'unites : n'ont de sens qu'au-dela d'une unite entiere. -->
      <div v-if="count > 1" class="units">
        <button class="u" :class="{ on: current === TOUTES }" @click="current = TOUTES">Toutes ({{ count }})</button>
        <button v-for="(r, i) in resumes" :key="i" class="u" :class="{ on: current === i, filled: !!r }" @click="current = i">
          {{ i + 1 }}<span v-if="r" class="dot" aria-hidden="true"></span>
        </button>
      </div>
      <p v-if="count > 1 && current === TOUTES && !identiques" class="tiny warn">
        Les unités ont des remarques différentes. Ce que vous touchez ici les remplacera toutes ;
        passez par les onglets numérotés pour n'en changer qu'une.
      </p>

      <div v-if="notes.length" class="chips">
        <button v-for="n in notes" :key="n.id" class="chip" :class="{ on: shown.picked.includes(n.label) }" @click="toggle(n)">
          <Icon v-if="shown.picked.includes(n.label)" name="check" :size="14" :stroke="2.6" />
          {{ n.label }}
        </button>
      </div>
      <p v-else class="tiny muted">Aucune remarque enregistrée. Ajoutez-en dans Back-office → Remarques cuisine.</p>

      <div class="field">
        <label>Remarque libre{{ count > 1 ? (current === TOUTES ? ' — toutes les unités' : ' — unité ' + (current + 1)) : '' }}</label>
        <input class="input" :value="shown.free" placeholder="ex. cuisson à point, sans pain…"
               @input="setFree($event.target.value)" @keyup.enter="validate" />
      </div>

      <!-- Recapitulatif : ce que la cuisine lira, ligne par ligne. -->
      <ul v-if="count > 1" class="recap">
        <li v-for="(r, i) in resumes" :key="i" :class="{ pick: current === i }">
          <b>{{ i + 1 }}</b><span v-if="r">{{ r }}</span><span v-else class="muted">aucune remarque</span>
        </li>
      </ul>
      <p v-else class="recap-one">
        <b class="num">{{ fmtQty(quantity) }} ×</b> {{ line.product?.name }}
        <span v-if="resumes[0]"> — <b>{{ resumes[0] }}</b></span>
        <span v-else class="muted"> — aucune remarque</span>
      </p>
    </div>

    <template #foot>
      <button class="btn lg danger" v-if="line.note" @click="clear">Retirer</button>
      <button class="btn lg" @click="emit('close')">Annuler</button>
      <button class="btn lg primary" @click="validate">Valider</button>
    </template>
  </Modal>
</template>

<style scoped>
.units { display: flex; flex-wrap: wrap; gap: 6px; }
.u {
  position: relative; min-width: 46px; min-height: 40px; padding: 0 14px; border: 1px solid var(--line);
  border-radius: var(--r-sm); background: var(--surface); font-size: 15px; font-weight: 650;
}
.u.on { border-color: var(--ink); background: var(--ink); color: #fff; }
.u .dot { position: absolute; top: 6px; right: 6px; width: 6px; height: 6px; border-radius: 50%; background: var(--accent); }
.u.on .dot { background: #fff; }
.warn { margin: 0; padding: 8px 11px; border-radius: var(--r-sm); background: var(--brand-soft); color: var(--brand); }

.chips { display: flex; flex-wrap: wrap; gap: 7px; }
.chip {
  display: inline-flex; align-items: center; gap: 6px; min-height: 42px; padding: 0 14px;
  border: 1px solid var(--line); border-radius: 999px; background: var(--surface); font-size: 14.5px; font-weight: 550;
}
.chip:hover { border-color: var(--ink-4); background: var(--surface-2); }
.chip.on { border-color: var(--accent); background: var(--accent-soft); color: var(--ink); font-weight: 700; }

.recap { list-style: none; margin: 0; padding: 8px 10px; border-radius: var(--r-sm); background: var(--surface-2); display: flex; flex-direction: column; gap: 3px; }
.recap li { display: flex; align-items: baseline; gap: 9px; font-size: 13.5px; }
.recap li b { flex: none; min-width: 18px; font-variant-numeric: tabular-nums; color: var(--ink-3); }
.recap li.pick { font-weight: 650; }
.recap-one { margin: 0; padding: 10px 12px; border-radius: var(--r-sm); background: var(--surface-2); font-size: 14px; }
</style>
