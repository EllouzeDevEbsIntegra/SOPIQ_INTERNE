<script setup>
/**
 * Remarques de cuisine sur une ligne du panier.
 *
 * Les remarques courantes se touchent dans une liste tenue au back-office ; tout le reste
 * s'écrit librement. Quand la ligne porte plusieurs unités, la remarque s'applique par
 * défaut à toutes, mais peut ne concerner qu'une partie : deux « sans oignon » et un
 * ordinaire. La ligne se scinde alors, ce que la cuisine doit lire de toute façon.
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

/* La note enregistree est un simple texte : on retrouve les remarques connues pour les
   re-cocher, et ce qui n'en fait pas partie retourne dans la saisie libre. */
const parts = String(props.line?.note || '').split(',').map(t => t.trim()).filter(Boolean)
const picked = ref(new Set(parts.filter(t => labels.value.has(t))))
const free = ref(parts.filter(t => !labels.value.has(t)).join(', '))

const maxQty = computed(() => Math.max(1, Math.floor(Number(props.line?.quantity) || 1)))
const qty = ref(maxQty.value)

const result = computed(() => {
  const chosen = notes.value.filter(n => picked.value.has(n.label)).map(n => n.label)
  const libre = free.value.trim()
  return [...chosen, libre].filter(Boolean).join(', ')
})

function toggle(n) {
  const s = new Set(picked.value)
  s.has(n.label) ? s.delete(n.label) : s.add(n.label)
  picked.value = s
}
const validate = () => emit('ok', { note: result.value, quantity: qty.value })
const clear = () => emit('ok', { note: '', quantity: maxQty.value })
</script>

<template>
  <Modal size="md" :title="'Remarques — ' + (line.product?.name || '')" @close="emit('close')">
    <div class="col gap-16">
      <!-- Repartition : n'a de sens qu'au-dela d'une unite. -->
      <div v-if="maxQty > 1" class="split">
        <span class="lbl">Appliquer à</span>
        <div class="qtys">
          <button v-for="n in maxQty" :key="n" class="q" :class="{ on: qty === n }" @click="qty = n">
            {{ n === maxQty ? 'Tous (' + n + ')' : n }}
          </button>
        </div>
        <p v-if="qty < maxQty" class="tiny muted note-split">
          La ligne sera séparée : {{ fmtQty(qty) }} avec cette remarque,
          {{ fmtQty(maxQty - qty) }} sans changement.
        </p>
      </div>

      <div v-if="notes.length" class="chips">
        <button v-for="n in notes" :key="n.id" class="chip" :class="{ on: picked.has(n.label) }" @click="toggle(n)">
          <Icon v-if="picked.has(n.label)" name="check" :size="14" :stroke="2.6" />
          {{ n.label }}
        </button>
      </div>
      <p v-else class="tiny muted">
        Aucune remarque enregistrée. Ajoutez-en dans Back-office → Remarques cuisine.
      </p>

      <div class="field">
        <label>Remarque libre</label>
        <input class="input" v-model="free" placeholder="ex. cuisson à point, sans pain…" @keyup.enter="validate" />
      </div>

      <p class="preview">
        <b class="num">{{ fmtQty(qty) }} ×</b> {{ line.product?.name }}
        <span v-if="result"> — <b>{{ result }}</b></span>
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
.split { display: flex; flex-direction: column; gap: 8px; }
.split .lbl { font-size: 11.5px; font-weight: 700; letter-spacing: .05em; text-transform: uppercase; color: var(--ink-3); }
.qtys { display: flex; flex-wrap: wrap; gap: 6px; }
.q {
  min-width: 46px; min-height: 40px; padding: 0 14px; border: 1px solid var(--line);
  border-radius: var(--r-sm); background: var(--surface); font-size: 15px; font-weight: 650;
}
.q.on { border-color: var(--ink); background: var(--ink); color: #fff; }
.note-split { margin: 0; }

.chips { display: flex; flex-wrap: wrap; gap: 7px; }
.chip {
  display: inline-flex; align-items: center; gap: 6px; min-height: 42px; padding: 0 14px;
  border: 1px solid var(--line); border-radius: 999px; background: var(--surface); font-size: 14.5px; font-weight: 550;
}
.chip:hover { border-color: var(--ink-4); background: var(--surface-2); }
.chip.on { border-color: var(--accent); background: var(--accent-soft); color: var(--ink); font-weight: 700; }

.preview { margin: 0; padding: 10px 12px; border-radius: var(--r-sm); background: var(--surface-2); font-size: 14px; }
</style>
