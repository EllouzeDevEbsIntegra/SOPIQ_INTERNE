<script setup>
/**
 * Le stock des pâtes, tenu depuis la caisse.
 *
 * Ce qui s'épuise dans un fast-food à mlewi, ce n'est pas un article : c'est la pâte. La
 * même pâte normale sert quarante sandwichs, et c'est elle qui manque à 21 h. L'écran
 * montre donc un compteur par pâte, gros, lisible de loin — c'est le chiffre que le
 * caissier vient vérifier entre deux clients.
 *
 * Deux gestes, et un seul écran pour les deux : on reçoit un paquet de pâtes (entrée),
 * on en déchire une (casse). La casse porte un motif, parce qu'un stock qui descend sans
 * vente est exactement ce qu'on cherchera à comprendre le soir.
 */
import { computed, onMounted, ref } from 'vue'
import Modal from '../common/Modal.vue'
import Icon from '../common/Icon.vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { fmtQty } from '../../utils/money'
import { fmtTime } from '../../utils/dates'

const emit = defineEmits(['close', 'changed'])
const ui = useUiStore()
const etat = ref(null)
const saisie = ref({})          // variantValueId -> quantité tapée
const busy = ref(false)
const casse = ref(null)         // la ligne dont on déclare une perte
const motif = ref('')
const detail = ref(false)

async function charger(x) {
  try { etat.value = x || await api.pos.stock() } catch (e) { ui.error(e.humanMessage || e) }
}
onMounted(() => charger())

const lignes = computed(() => etat.value?.lines || [])
const rien = computed(() => !lignes.value.length)
const total = computed(() => lignes.value.reduce((s, l) => s + Number(l.quantity), 0))

function tape(l, k) {
  const v = String(saisie.value[l.variantValueId] || '')
  saisie.value[l.variantValueId] = k === 'C' ? '' : k === '<' ? v.slice(0, -1) : (v + k).slice(0, 5)
}
const saisi = (l) => Number(saisie.value[l.variantValueId] || 0)

/** Tout ce qui a été tapé part d'un coup : le caissier compte ses paquets, puis valide. */
async function entrer() {
  const aFaire = lignes.value.filter(l => saisi(l) > 0)
  if (!aFaire.length) return ui.error('Saisissez une quantité à ajouter.')
  busy.value = true
  try {
    let dernier = null
    for (const l of aFaire) dernier = await api.pos.stockEntry({ variantValueId: l.variantValueId, quantity: saisi(l) })
    saisie.value = {}
    await charger(dernier)
    ui.success('Stock mis à jour')
    emit('changed')
  } catch (e) { ui.error(e.humanMessage || e) } finally { busy.value = false }
}

async function declarerCasse() {
  const q = Number(motif.value.q || 0)
  if (!(q > 0)) return ui.error('Indiquez la quantité perdue.')
  busy.value = true
  try {
    const r = await api.pos.stockWaste({ variantValueId: casse.value.variantValueId, quantity: q, comment: motif.value.raison || null })
    casse.value = null
    await charger(r)
    ui.success('Perte enregistrée')
    emit('changed')
  } catch (e) { ui.error(e.humanMessage || e) } finally { busy.value = false }
}

function ouvrirCasse(l) { casse.value = l; motif.value = { q: '', raison: '' } }

const LIBELLE = { ENTREE: 'Entrée', VENTE: 'Vente', CASSE: 'Perte', ANNULATION: 'Annulation', REMISE_A_ZERO: 'Remise à zéro' }
const signe = (v) => (Number(v) > 0 ? '+' : '') + fmtQty(v)
</script>

<template>
  <Modal size="lg" title="Stock des pâtes" @close="emit('close')">
    <div v-if="!etat" class="spinner"></div>
    <div v-else class="col gap-12">
      <div class="row between wrap gap-8">
        <span class="muted small">{{ etat.pointOfSaleName }} · {{ lignes.length }} pâte(s) suivie(s) · {{ fmtQty(total) }} en stock</span>
        <button class="btn sm" @click="detail = !detail">{{ detail ? 'Masquer' : 'Voir' }} les mouvements du jour</button>
      </div>

      <p v-if="rien" class="vide">
        Aucune pâte n'est suivie en stock. Cochez « Compteur propre » sur les versions concernées
        dans <b>Back-office → Variantes</b>, puis revenez ici saisir les quantités.
      </p>

      <div v-else class="pates">
        <div v-for="l in lignes" :key="l.variantValueId" class="pate" :class="{ vide: Number(l.quantity) <= 0 }">
          <div class="tete">
            <span class="nom">{{ l.valueName }}</span>
            <span class="axe tiny muted">{{ l.variantName }}</span>
          </div>
          <!-- Le stock actuel, en gros : c'est ce que le caissier vient chercher. -->
          <b class="reste num">{{ fmtQty(l.quantity) }}</b>
          <div v-if="l.borrowers?.length" class="tiny muted lie">tire aussi : {{ l.borrowers.join(' · ') }}</div>
          <div class="ajout">
            <input class="input num" :value="saisie[l.variantValueId] || ''" readonly placeholder="0"
                   @focus="$event.target.blur()" />
            <div class="pad">
              <button v-for="k in ['1','2','3','4','5','6','7','8','9','0']" :key="k" class="k" @click="tape(l, k)">{{ k }}</button>
              <button class="k min" @click="tape(l, '<')">⌫</button>
              <button class="k min" @click="tape(l, 'C')">C</button>
            </div>
          </div>
          <button class="btn sm perte" @click="ouvrirCasse(l)"><Icon name="minus" :size="14" />Déclarer une perte</button>
        </div>
      </div>

      <div v-if="detail" class="mouvements">
        <div v-if="!etat.movements.length" class="tiny muted">Aucun mouvement aujourd'hui.</div>
        <div v-for="m in etat.movements" :key="m.id" class="mvt">
          <span class="h tiny muted">{{ fmtTime(m.createdAt) }}</span>
          <span class="q num" :class="{ moins: Number(m.quantity) < 0 }">{{ signe(m.quantity) }}</span>
          <span class="n">{{ m.valueName }}</span>
          <span class="t tiny">{{ LIBELLE[m.type] || m.type }}</span>
          <span class="c tiny muted">{{ m.comment || m.userName || '' }}</span>
          <span class="r num tiny muted">reste {{ fmtQty(m.resulting) }}</span>
        </div>
      </div>
    </div>

    <template #foot>
      <button class="btn lg" @click="emit('close')">Fermer</button>
      <button class="btn lg primary" :disabled="busy || rien" @click="entrer"><Icon name="plus" :size="17" />Ajouter au stock</button>
    </template>
  </Modal>

  <Modal v-if="casse" size="sm" :title="'Perte — ' + casse.valueName" @close="casse = null">
    <div class="col gap-12">
      <p class="tiny muted">Pâte déchirée, tombée, abîmée. Le mouvement part au journal de caisse avec votre nom.</p>
      <div class="field"><label>Quantité perdue</label><input class="input num" v-model="motif.q" inputmode="decimal" autofocus placeholder="1" /></div>
      <div class="field"><label>Motif (facultatif)</label><input class="input" v-model="motif.raison" maxlength="120" placeholder="ex. pâte déchirée" /></div>
      <div class="tiny muted">Il reste {{ fmtQty(casse.quantity) }} « {{ casse.valueName }} ».</div>
    </div>
    <template #foot>
      <button class="btn lg" @click="casse = null">Annuler</button>
      <button class="btn lg danger solid" :disabled="busy" @click="declarerCasse">Retirer du stock</button>
    </template>
  </Modal>
</template>

<style scoped>
.vide { background: var(--surface-2); border: 1px solid var(--line); border-radius: var(--r); padding: 14px; color: var(--ink-2); font-size: 14px; }
.pates { display: grid; grid-template-columns: repeat(auto-fill, minmax(215px, 1fr)); gap: 12px; }
.pate { border: 1px solid var(--line); border-radius: var(--r); padding: 12px; background: var(--surface-2); display: flex; flex-direction: column; gap: 8px; }
/* Une pâte épuisée se voit avant d'être lue : c'est elle qui va faire refuser une vente. */
.pate.vide { border-color: var(--danger-line); background: var(--danger-soft); }
.tete { display: flex; align-items: baseline; justify-content: space-between; gap: 8px; }
.nom { font-weight: 650; font-size: 15px; }
.reste { font-family: var(--font-display); font-size: 34px; line-height: 1; letter-spacing: -.02em; }
.pate.vide .reste { color: var(--danger); }
.lie { margin-top: -4px; }
.ajout .input { text-align: right; font-size: 18px; height: 40px; }
.pad { display: grid; grid-template-columns: repeat(4, 1fr); gap: 4px; margin-top: 6px; }
.k { height: 34px; border: 1px solid var(--line); border-radius: 8px; background: var(--surface); font: 600 15px/1 inherit; }
.k:active { transform: translateY(1px); }
.k.min { color: var(--ink-3); }
.perte { align-self: flex-start; }
.mouvements { border-top: 1px solid var(--line); padding-top: 10px; max-height: 220px; overflow: auto; }
.mvt { display: grid; grid-template-columns: 52px 58px 1fr 88px 1fr 90px; gap: 8px; align-items: baseline; padding: 4px 0; border-bottom: 1px solid var(--line); font-size: 13.5px; }
.mvt .q { font-weight: 700; text-align: right; color: var(--success); }
.mvt .q.moins { color: var(--danger); }
.mvt .r { text-align: right; }
</style>
