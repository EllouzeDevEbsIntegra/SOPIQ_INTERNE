<script setup>
/**
 * Choix du destinataire d'un ticket : un client, ou un livreur.
 *
 * La liste s'affiche dès l'ouverture, sans rien avoir à taper : en caisse on choisit
 * presque toujours quelqu'un de connu, et obliger à saisir un critère pour voir
 * apparaître trois noms coûte un geste à chaque commande. La zone de recherche ne sert
 * qu'au-delà : elle interroge le serveur, qui voit plus loin que la page chargée.
 *
 * Un clic sur une ligne vaut choix : le dialogue se ferme aussitôt. Un client de passage
 * peut aussi être saisi au vol, sans créer de fiche — un livreur, non : c'est son compte
 * qui portera la course, et un compte se crée au back-office.
 */
import { computed, onMounted, ref, watch } from 'vue'
import Modal from '../common/Modal.vue'
import Icon from '../common/Icon.vue'
import { api } from '../../api'

const props = defineProps({ initial: Object, party: { type: String, default: 'CUSTOMER' } })
const emit = defineEmits(['close', 'ok'])
const courier = props.party === 'COURIER'

const q = ref('')
const rows = ref([])
const loading = ref(true)
const walkIn = ref({ name: props.initial?.id ? '' : (props.initial?.name || ''), phone: props.initial?.id ? '' : (props.initial?.phone || '') })
let timer = null

const fetchList = (v) => courier ? api.admin.couriers(v, true) : api.admin.customers(v)
async function load(v = '') {
  loading.value = true
  try { rows.value = await fetchList(v) } catch { rows.value = [] } finally { loading.value = false }
}
onMounted(() => load(''))
watch(q, v => { clearTimeout(timer); timer = setTimeout(() => load(v.trim()), 250) })

const title = computed(() => courier ? 'Choisir le livreur' : 'Choisir le client')
const empty = computed(() => {
  if (q.value.trim()) return 'Aucun résultat pour « ' + q.value.trim() + ' ».'
  return courier ? 'Aucun livreur actif. Créez-en un dans Back-office → Livreurs.'
                 : 'Aucun client enregistré. Vous pouvez saisir un client de passage ci-dessous.'
})

const pick = (c) => emit('ok', { id: c.id, name: c.name, phone: c.phone || '' })
const clear = () => emit('ok', { id: null, name: '', phone: '' })
function useWalkIn() {
  const name = walkIn.value.name.trim()
  if (!name) return
  emit('ok', { id: null, name, phone: walkIn.value.phone.trim() })
}
</script>

<template>
  <Modal :title="title" @close="emit('close')">
    <div class="pick">
      <div class="search">
        <Icon name="search" :size="16" />
        <input class="input" v-model="q" :placeholder="courier ? 'Rechercher un livreur…' : 'Rechercher un client…'" autofocus />
        <span v-if="!loading" class="tiny muted count">{{ rows.length }}</span>
      </div>

      <div class="list scroll">
        <button v-for="c in rows" :key="c.id" class="row" :class="{ on: c.id === initial?.id }" @click="pick(c)">
          <span class="nm">{{ c.name }}</span>
          <span v-if="c.phone" class="ph">{{ c.phone }}</span>
          <Icon v-if="c.id === initial?.id" name="check" :size="16" class="tick" />
        </button>
        <p v-if="!rows.length" class="muted small blank">{{ loading ? 'Chargement…' : empty }}</p>
      </div>

      <details v-if="!courier" class="walkin" :open="!!walkIn.name">
        <summary>Client de passage (sans fiche)</summary>
        <div class="row-2">
          <input class="input" v-model="walkIn.name" placeholder="Nom" @keyup.enter="useWalkIn" />
          <input class="input" v-model="walkIn.phone" inputmode="tel" placeholder="Téléphone" @keyup.enter="useWalkIn" />
          <button class="btn primary" :disabled="!walkIn.name.trim()" @click="useWalkIn">Utiliser</button>
        </div>
      </details>
    </div>

    <template #foot>
      <button class="btn lg danger" v-if="initial?.name" @click="clear">Retirer</button>
      <button class="btn lg" @click="emit('close')">Annuler</button>
    </template>
  </Modal>
</template>

<style scoped>
.pick { display: flex; flex-direction: column; gap: 12px; }

.search { position: relative; display: flex; align-items: center; }
.search svg { position: absolute; left: 12px; color: var(--ink-4); pointer-events: none; }
.search .input { padding-left: 36px; padding-right: 44px; font-size: 15px; min-height: 46px; }
.search .count { position: absolute; right: 14px; font-weight: 700; color: var(--ink-4); }

.list { display: flex; flex-direction: column; gap: 4px; max-height: 48vh; min-height: 120px; }
.row {
  display: flex; align-items: center; gap: 10px; width: 100%; min-height: 48px; padding: 0 14px;
  border: 1px solid var(--line); border-radius: var(--r-sm); background: var(--surface);
  text-align: left; font-size: 15px;
}
.row:hover { background: var(--surface-2); border-color: var(--ink-4); }
.row.on { border-color: var(--accent); background: var(--accent-soft); }
.nm { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-weight: 600; }
.ph { flex: none; font-size: 13px; color: var(--ink-3); font-variant-numeric: tabular-nums; }
.tick { flex: none; color: var(--accent); }
.blank { padding: 22px 4px; text-align: center; }

.walkin { border-top: 1px solid var(--line); padding-top: 10px; }
.walkin summary { cursor: pointer; font-size: 13px; font-weight: 650; color: var(--ink-3); }
.walkin .row-2 { display: grid; grid-template-columns: minmax(0, 1.4fr) minmax(0, 1fr) auto; gap: 8px; margin-top: 10px; }
</style>
