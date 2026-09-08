<script setup>
/*
    La numerotation des tickets.

    Deux questions, tenues separement parce qu'elles n'ont rien a voir : QUAND le
    compteur repart a 1 (jour, mois, annee, jamais - et par point de vente, par caisse),
    et CE QUI S'IMPRIME sur le ticket. Avant, la seconde decidait de la premiere en
    silence : imprimer l'annee remettait a zero chaque 1er janvier, qu'on le veuille ou
    non.

    L'ecran ne recalcule rien tout seul. Chaque changement va demander au serveur le
    numero qu'il sortirait - c'est le meme calcul que la vente, sur des reglages qui ne
    sont pas encore ecrits. Ce qui est montre est donc ce qui sortira, pas une imitation
    qui pourrait deriver.
*/
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import Modal from '../../components/common/Modal.vue'

const ui = useUiStore(); const { busy, run } = useBusy()

const etat = ref(null)          // ce que le serveur repond pour le reglage propose
const enregistre = ref(null)    // ce qui est reellement en vigueur
const form = reactive({ pattern: '', resetPeriod: 'YEARLY', perPos: true, perRegister: false, displayPattern: '' })
const champ = ref(null)
const compteur = ref(null)

const REMISES = [
  { code: 'NONE', titre: 'Continue', dit: 'Le compteur ne repart jamais à zéro. Le numéro grandit indéfiniment.' },
  { code: 'DAILY', titre: 'Journalière', dit: 'Le compteur repart à 1 chaque matin. La date doit figurer sur le ticket.' },
  { code: 'MONTHLY', titre: 'Mensuelle', dit: 'Le compteur repart à 1 le 1er de chaque mois.' },
  { code: 'YEARLY', titre: 'Annuelle', dit: 'Le compteur repart à 1 le 1er janvier. C’est le réglage livré.' }
]

const JETONS = [
  { j: '{POS}', dit: 'code du point de vente' },
  { j: '{REG}', dit: 'code de la caisse' },
  { j: '{YYYY}', dit: 'année sur 4 chiffres' },
  { j: '{YY}', dit: 'année sur 2 chiffres' },
  { j: '{MM}', dit: 'mois' },
  { j: '{DD}', dit: 'jour' },
  { j: '{SEQ:6}', dit: 'compteur, ici sur 6 chiffres' }
]

/*
    L'affichage : ce que le caissier et le client lisent. La reference peut porter la
    date, le point de vente et la caisse - c'est la comptabilite qui en a besoin ; sur le
    papier, un numero court se retient et s'annonce au comptoir.
*/
const AFFICHAGES = [
  { p: '', dit: 'Le numéro complet, tel qu’il est enregistré' },
  { p: '{SEQ:4}', dit: 'Le compteur seul' },
  { p: '{REG}-{SEQ:3}', dit: 'Caisse et compteur' },
  { p: 'N° {SEQ:3}', dit: 'Précédé de « N° »' },
  { p: 'Ticket {SEQ:4}', dit: 'Précédé de « Ticket »' }
]

const MODELES = [
  { p: '{POS}-{YYYY}-{SEQ:6}', dit: 'Point de vente, année, compteur' },
  { p: '{SEQ:6}', dit: 'Le compteur seul' },
  { p: '{POS}-{YYYY}{MM}{DD}-{SEQ:4}', dit: 'Point de vente et date du jour' },
  { p: '{POS}{REG}-{YY}{MM}{DD}-{SEQ:3}', dit: 'Jusqu’à la caisse, date courte' },
  { p: '{POS}/{YYYY}{MM}/{SEQ:5}', dit: 'Point de vente et mois' }
]

const soucis = computed(() => etat.value?.problems || [])
/* Les compteurs sont ceux EN VIGUEUR, jamais ceux d'un reglage propose : une simulation
   ne cree pas de compteur, et montrer les compteurs d'un reglage non enregistre ferait
   croire qu'ils existent. */
const compteurs = computed(() => enregistre.value?.counters || [])
const modifie = computed(() => !!enregistre.value && (
  form.pattern !== enregistre.value.pattern || form.resetPeriod !== enregistre.value.resetPeriod ||
  form.perPos !== enregistre.value.perPos || form.perRegister !== enregistre.value.perRegister ||
  form.displayPattern !== (enregistre.value.displayPattern || '')))

function poser(d) {
  enregistre.value = d; etat.value = d
  form.pattern = d.pattern; form.resetPeriod = d.resetPeriod
  form.perPos = d.perPos; form.perRegister = d.perRegister
  form.displayPattern = d.displayPattern || ''
}

onMounted(async () => {
  try { poser(await api.admin.ticketNumbering()) } catch (e) { ui.error(e.humanMessage) }
})

/* Un appel par frappe serait inutile : on attend que la main s'arrete. */
let minuteur = null
watch(() => ({ ...form }), () => {
  if (!enregistre.value) return
  clearTimeout(minuteur)
  minuteur = setTimeout(async () => {
    try { etat.value = await api.admin.previewTicketNumbering({ ...form }) } catch (e) { ui.error(e.humanMessage) }
  }, 260)
}, { deep: true })

/** Poser un jeton la ou est le curseur, pas au bout : on corrige souvent le milieu. */
function inserer(jeton) {
  const el = champ.value
  const i = el && el.selectionStart != null ? el.selectionStart : form.pattern.length
  const f = el && el.selectionEnd != null ? el.selectionEnd : i
  form.pattern = form.pattern.slice(0, i) + jeton + form.pattern.slice(f)
  requestAnimationFrame(() => { if (el) { el.focus(); el.setSelectionRange(i + jeton.length, i + jeton.length) } })
}

/**
 * Ajouter au format ce qui manque pour que la portee demandee tienne. Le refus du
 * serveur explique le probleme ; ce bouton le repare, plutot que de laisser l'exploitant
 * deviner ou poser {MM} dans son gabarit.
 */
function corriger() {
  const m = /\{SEQ(?::\d+)?\}/.exec(form.pattern)
  if (!m) { form.pattern = (form.pattern + '{SEQ:6}').trim(); return }
  const p = form.pattern
  const manque = []
  if (form.perPos && !p.includes('{POS}')) manque.push('{POS}')
  if (form.perRegister && !p.includes('{REG}')) manque.push('{REG}')
  if (form.resetPeriod !== 'NONE') {
    const date = []
    if (!p.includes('{YYYY}') && !p.includes('{YY}')) date.push('{YYYY}')
    if (form.resetPeriod !== 'YEARLY' && !p.includes('{MM}')) date.push('{MM}')
    if (form.resetPeriod === 'DAILY' && !p.includes('{DD}')) date.push('{DD}')
    if (date.length) manque.push(date.join(''))
  }
  if (!manque.length) return
  const avant = p.slice(0, m.index).replace(/[-/_.]+$/, '')
  form.pattern = [avant, manque.join(''), p.slice(m.index)].filter(Boolean).join('-')
}

async function enregistrer() {
  const r = await run(() => api.admin.saveTicketNumbering({ ...form }), { success: 'Numérotation enregistrée' })
  if (r) poser(r)
}

async function poserCompteur() {
  const c = compteur.value
  const r = await run(() => api.admin.setTicketCounter(c.scopeKey, Number(c.nextValue)),
    { success: 'Compteur posé' })
  if (r) { compteur.value = null; poser(r) }
}
</script>

<template>
  <div v-if="etat" class="numerotation">
    <!-- Ce qui sortira de la caisse : c'est cela qu'on relit, pas le gabarit. -->
    <div class="card apercu" :class="{ faux: soucis.length }">
      <div>
        <div class="card-title">Prochain ticket</div>
        <div v-if="etat.sample" class="exemple num">{{ etat.displaySample }}</div>
        <div v-else class="exemple faux-txt">réglage impossible</div>
        <div v-if="etat.sample && etat.displaySample !== etat.sample" class="small muted reference">
          imprimé sur le ticket · en base : <b class="mono">{{ etat.sample }}</b>
        </div>
        <div class="small muted">
          Compteur <b>{{ etat.scopeLabel }}</b> · prochain numéro <b class="num">{{ etat.nextValue }}</b>
          <span v-if="modifie" class="badge warning" style="margin-left:8px">non enregistré</span>
        </div>
      </div>
      <button class="btn primary lg" :disabled="busy || !!soucis.length || !modifie" @click="enregistrer">
        Enregistrer la numérotation
      </button>
    </div>

    <div v-if="soucis.length" class="card ennuis">
      <div class="card-title">Ce réglage fabriquerait des doublons</div>
      <p v-for="(s, i) in soucis" :key="i">{{ s }}</p>
      <p class="small muted">
        Deux tickets ne peuvent pas porter le même numéro : c’est la référence d’une vente.
        Tout ce qui découpe le compteur doit donc se lire sur le ticket.
      </p>
      <button class="btn" @click="corriger">Compléter le format automatiquement</button>
    </div>

    <div class="grid-2">
      <!-- 1. Quand le compteur repart a 1 -->
      <div class="card">
        <div class="card-title">Remise à zéro du compteur</div>
        <div class="choix">
          <label v-for="r in REMISES" :key="r.code" class="opt" :class="{ on: form.resetPeriod === r.code }">
            <input type="radio" name="remise" :value="r.code" v-model="form.resetPeriod" />
            <span><b>{{ r.titre }}</b><i>{{ r.dit }}</i></span>
          </label>
        </div>
        <div class="section-title">Un compteur séparé pour…</div>
        <label class="check"><input type="checkbox" v-model="form.perPos" /> Chaque point de vente</label>
        <div class="tiny muted indent">Deux boutiques numérotent chacune de leur côté. Le format doit porter {POS}.</div>
        <label class="check"><input type="checkbox" v-model="form.perRegister" /> Chaque caisse</label>
        <div class="tiny muted indent">Chaque caisse tient sa propre série. Le format doit porter {REG}.</div>
        <div class="tiny muted mt-8">
          Décoché, le compteur est commun : les caisses se partagent une seule suite de numéros,
          sans trou ni doublon.
        </div>
      </div>

      <!-- 2. Ce qui s'imprime -->
      <div class="card">
        <div class="card-title">Format imprimé sur le ticket</div>
        <div class="field">
          <label>Gabarit</label>
          <input ref="champ" class="input mono" v-model="form.pattern" spellcheck="false" />
        </div>
        <div class="jetons">
          <button v-for="j in JETONS" :key="j.j" class="btn sm mono" :title="j.dit" @click="inserer(j.j)">{{ j.j }}</button>
        </div>
        <div class="tiny muted">
          {{ JETONS.map(j => j.j + ' ' + j.dit).join(' · ') }}. Le chiffre après {SEQ} est le nombre de
          chiffres du compteur : {SEQ:4} donne 0001.
        </div>
        <div class="section-title">Formats courants</div>
        <div class="modeles">
          <button v-for="m in MODELES" :key="m.p" class="modele" :class="{ on: form.pattern === m.p }"
                  @click="form.pattern = m.p">
            <b class="mono">{{ m.p }}</b><i>{{ m.dit }}</i>
          </button>
        </div>
      </div>
    </div>

    <!-- 3. Ce que le client lit -->
    <div class="card">
      <div class="card-title">Affiché à la caisse et sur le ticket</div>
      <p class="small muted">
        La référence ci-dessus reste enregistrée entière, pour la comptabilité et les recherches.
        Ce réglage-ci ne décide que de ce qui s’écrit sur le papier et à l’écran de vente — un
        client n’a pas à lire l’année, la date et le numéro de caisse pour retrouver sa commande.
      </p>
      <div class="modeles" style="margin-bottom:10px">
        <button v-for="a in AFFICHAGES" :key="a.p" class="modele" :class="{ on: form.displayPattern === a.p }"
                @click="form.displayPattern = a.p">
          <b class="mono">{{ a.p || '(le numéro complet)' }}</b><i>{{ a.dit }}</i>
        </button>
      </div>
      <div class="field">
        <label>Ou un affichage à vous</label>
        <input class="input mono" v-model="form.displayPattern" spellcheck="false"
               placeholder="vide = le numéro complet" />
      </div>
      <div class="tiny muted mt-8">
        Mêmes jetons que le format, et le texte que vous tapez autour est imprimé tel quel :
        <code>N° {SEQ:3}</code> donne <code>N° 001</code>. Le ticket n’ajoute plus rien de lui-même —
        si vous voulez un libellé devant le numéro, écrivez-le ici. {SEQ} est obligatoire dès que le
        champ n’est pas vide, sinon tous les tickets afficheraient la même chose. Les tickets déjà
        imprimés gardent le numéro qu’ils portent : une réimpression rend le ticket que le client a gardé.
      </div>
    </div>

    <!-- 4. Les compteurs eux-memes -->
    <div class="card">
      <div class="card-title">Compteurs</div>
      <p class="small muted">
        Un compteur par portée. Ceux des périodes passées sont gardés pour mémoire : les modifier
        ne changerait aucun numéro à venir.
        <b v-if="modifie">Ce tableau montre la numérotation en vigueur, pas le réglage en cours de saisie.</b>
      </p>
      <div class="table-wrap"><table class="table">
        <thead><tr><th>Portée</th><th>Prochain numéro</th><th>Donnerait</th><th></th></tr></thead>
        <tbody>
          <tr v-for="c in compteurs" :key="c.scopeKey">
            <td><b>{{ c.label }}</b> <span v-if="c.current" class="badge success">en cours</span></td>
            <td class="num">{{ c.nextValue }}</td>
            <td class="mono muted">{{ c.sample || '—' }}</td>
            <td class="actions">
              <button v-if="c.current && !modifie" class="btn sm" @click="compteur = { ...c }">Modifier</button>
            </td>
          </tr>
        </tbody>
      </table></div>
    </div>

    <Modal v-if="compteur" title="Prochain numéro de ce compteur" @close="compteur = null">
      <div class="form-grid">
        <div class="field span-2"><label>Portée</label><div class="mono">{{ compteur.label }}</div></div>
        <div class="field"><label>Prochain numéro</label>
          <input class="input num" type="number" min="1" v-model.number="compteur.nextValue" /></div>
      </div>
      <p class="small muted">
        Un numéro déjà imprimé sera refusé : deux ventes ne peuvent pas partager leur référence.
        Pour repartir de 1, changez d’abord le format — la nouvelle série sera neuve.
      </p>
      <template #foot>
        <button class="btn lg" @click="compteur = null">Annuler</button>
        <button class="btn lg primary" :disabled="busy || !(compteur.nextValue >= 1)" @click="poserCompteur">Poser</button>
      </template>
    </Modal>
  </div>
</template>

<style scoped>
.numerotation { display: flex; flex-direction: column; gap: 16px; }
.apercu { display: flex; align-items: center; justify-content: space-between; gap: 20px; flex-wrap: wrap; }
.reference { margin-bottom: 2px; }
.exemple {
  font-family: var(--font-mono); font-size: 34px; font-weight: 700;
  letter-spacing: -.02em; line-height: 1.15; margin-bottom: 4px;
}
.apercu.faux { border-color: var(--danger-line); }
.faux-txt { color: var(--danger); font-size: 22px; }
.ennuis { border-color: var(--danger-line); background: var(--danger-soft); }
.ennuis p { margin: 0 0 8px; font-size: 14px; }
.ennuis .card-title { color: var(--danger); }

.choix { display: grid; gap: 8px; }
.opt {
  display: flex; align-items: flex-start; gap: 11px; padding: 11px 13px; cursor: pointer;
  border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface-2);
}
.opt.on { border-color: var(--brand); background: var(--brand-soft); }
.opt input { width: 18px; height: 18px; margin-top: 2px; accent-color: var(--brand); flex: none; }
.opt b { display: block; font-size: 14.5px; }
.opt i { display: block; font-style: normal; font-size: 12.5px; color: var(--ink-3); margin-top: 2px; }
.indent { margin: -6px 0 8px 30px; }

.mono { font-family: var(--font-mono); }
.jetons { display: flex; flex-wrap: wrap; gap: 6px; margin: 10px 0 8px; }
.modeles { display: grid; gap: 6px; }
.modele {
  display: flex; align-items: baseline; gap: 10px; flex-wrap: wrap; text-align: left;
  padding: 9px 12px; border: 1px solid var(--line-2); border-radius: var(--r-sm); background: var(--surface-2);
}
.modele.on { border-color: var(--brand); background: var(--brand-soft); }
.modele b { font-size: 13px; }
.modele i { font-style: normal; font-size: 12.5px; color: var(--ink-3); }
</style>
