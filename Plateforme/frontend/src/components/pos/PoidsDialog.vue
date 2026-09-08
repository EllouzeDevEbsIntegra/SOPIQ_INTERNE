<script setup>
/**
 * Vendre au poids : on tape un poids, ou un montant.
 *
 * POURQUOI DEUX FACONS D'ENTRER. Au comptoir d'une pâtisserie, les deux phrases se
 * disent autant : « 300 grammes de baklawa » et « pour 5 dinars de baklawa ». La
 * deuxième obligeait le vendeur à diviser de tête, devant le client, sur chaque vente.
 * La caisse fait la division, et montre les deux chiffres — poids ET montant — quel que
 * soit celui qu'on a tapé : personne n'a à faire confiance à un calcul qu'il ne voit pas.
 *
 * LE POIDS SE TAPE EN GRAMMES. « 300 » est ce que dit la balance et ce que dit le
 * client ; « 0,300 » est ce que veut la base de données. Demander la seconde forme au
 * coup de feu, c'est réclamer une conversion à chaque pesée — et se tromper d'un facteur
 * mille le jour où elle est oubliée. La ligne du panier, elle, reste en kilos.
 */
import { computed, ref } from 'vue'
import Modal from '../common/Modal.vue'
import NumPad from '../common/NumPad.vue'
import { fmt } from '../../utils/money'

const props = defineProps({
  product: { type: Object, required: true },
  /** Prix de l'unité entière (le kilo, le litre). */
  prix: { type: Number, required: true },
  /** Quantité déjà posée, en unités, quand on corrige une ligne. */
  initial: { type: Number, default: 0 }
})
const emit = defineEmits(['close', 'ok'])

const KG = props.product.unite === 'LITRE' ? 'L' : 'kg'
const SOUS = props.product.unite === 'LITRE' ? 'ml' : 'g'

/** « poids » : on tape des grammes. « montant » : on tape des dinars. */
const mode = ref('poids')
const saisie = ref('')
const nombre = computed(() => Number((saisie.value || '0').replace(',', '.')) || 0)

/*
    La quantité en unités entières, arrondie au millième — c'est la précision de la
    colonne en base, et celle d'une balance de commerce. Un chiffre de plus ne serait
    ni pesable ni facturable.
*/
const quantite = computed(() => {
  if (!props.prix) return 0
  const q = mode.value === 'poids' ? nombre.value / 1000 : nombre.value / props.prix
  return Math.round(q * 1000) / 1000
})
const total = computed(() => Math.round(quantite.value * props.prix * 1000) / 1000)

const grammes = computed(() => Math.round(quantite.value * 1000))
const vide = computed(() => quantite.value <= 0)

/** Les poids qu'on demande tous les jours : un geste au lieu de trois touches. */
const raccourcis = [100, 250, 500, 1000]

function poser(g) { mode.value = 'poids'; saisie.value = String(g) }
function valider() { if (!vide.value) emit('ok', quantite.value) }
</script>

<template>
  <Modal :title="`${product.name} — ${fmt(prix)} ${KG === 'L' ? 'le litre' : 'le kilo'}`" @close="emit('close')">
    <div class="pesee">
      <div class="bascule">
        <button :class="{ on: mode === 'poids' }" @click="mode = 'poids'; saisie = ''">Poids en {{ SOUS }}</button>
        <button :class="{ on: mode === 'montant' }" @click="mode = 'montant'; saisie = ''">Montant en dinars</button>
      </div>

      <!--
          Les deux chiffres, toujours. Celui qu'on tape est en gros ; l'autre est la
          reponse a la question que le client posera.
      -->
      <div class="resultat" :class="{ attente: vide }">
        <div class="gros num">{{ grammes }} <small>{{ SOUS }}</small></div>
        <div class="equiv num">= {{ fmt(total) }} DT</div>
        <div v-if="initial" class="tiny muted">Cette ligne portait {{ Math.round(initial * 1000) }} {{ SOUS }}.</div>
      </div>

      <div class="row wrap gap-8">
        <button v-for="g in raccourcis" :key="g" class="btn chip" @click="poser(g)">
          {{ g >= 1000 ? (g / 1000) + ' ' + KG : g + ' ' + SOUS }}
        </button>
      </div>

      <!-- Le pave n'affiche pas sa propre ligne : le bloc au-dessus montre deja le
           chiffre tape, et en plus grand. Deux affichages du meme nombre font hesiter. -->
      <NumPad v-model="saisie" :show-display="false" :mode="mode === 'poids' ? 'integer' : 'amount'"
              :ok-label="vide ? 'Entrez une quantité' : `Ajouter ${grammes} ${SOUS} — ${fmt(total)} DT`"
              @ok="valider" />
    </div>
  </Modal>
</template>

<style scoped>
.pesee { display: flex; flex-direction: column; gap: 12px; min-width: 320px }
.bascule { display: flex; gap: 6px }
.bascule button { flex: 1; padding: 10px; border: 1px solid var(--line); background: var(--surface);
                  border-radius: 10px; font-size: 14px; cursor: pointer }
.bascule button.on { background: var(--primary); color: #fff; border-color: var(--primary); font-weight: 600 }
.resultat { text-align: center; padding: 10px 8px; border: 1px solid var(--line); border-radius: 12px;
            background: var(--surface-2) }
.resultat.attente { opacity: .45 }
.gros { font-size: 30px; font-weight: 700; line-height: 1.1 }
.gros small { font-size: 16px; font-weight: 500; opacity: .7 }
.equiv { font-size: 17px; margin-top: 2px }
</style>
