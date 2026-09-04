<script setup>
/**
 * Choix du destinataire d'un ticket : un client, ou un livreur.
 *
 * Un client peut être saisi au vol (nom et téléphone libres) : le caissier ne va pas
 * créer une fiche pour un passage unique. Un livreur, lui, se choisit forcément dans la
 * liste : c'est son compte qui portera la course, et un compte se crée au back-office.
 */
import { onMounted, ref, watch } from 'vue'
import Modal from '../common/Modal.vue'
import { api } from '../../api'

const props = defineProps({ initial: Object, party: { type: String, default: 'CUSTOMER' } })
const emit = defineEmits(['close', 'ok'])
const courier = props.party === 'COURIER'
const name = ref(props.initial?.name || ''); const phone = ref(props.initial?.phone || ''); const id = ref(props.initial?.id || null)
const q = ref(''); const results = ref([]); let t = null

const search = (v) => courier ? api.admin.couriers(v, true) : api.admin.customers(v)
watch(q, v => { clearTimeout(t); t = setTimeout(async () => { results.value = await search(v.trim()).catch(() => []) }, 250) })
// La liste des livreurs est courte et connue : on l'affiche d'emblée, sans faire taper.
onMounted(async () => { if (courier) results.value = await search('').catch(() => []) })

function pick(c) {
  id.value = c.id; name.value = c.name; phone.value = c.phone || ''
  if (courier) emit('ok', { id: c.id, name: c.name, phone: c.phone || '' })
  else { results.value = []; q.value = '' }
}
function clear() { emit('ok', { id: null, name: '', phone: '' }) }
</script>

<template>
  <Modal :title="courier ? 'Livreur' : 'Client (facultatif)'" @close="emit('close')">
    <div class="col gap-16">
      <div class="field">
        <label>{{ courier ? 'Choisir un livreur' : 'Rechercher un client existant' }}</label>
        <input class="input" v-model="q" :placeholder="courier ? 'Filtrer par nom ou téléphone…' : 'Nom ou téléphone…'" />
      </div>
      <div v-if="results.length" class="col gap-4 list">
        <button v-for="c in results" :key="c.id" class="btn soft" :class="{ on: c.id === id }" style="justify-content:flex-start" @click="pick(c)">
          {{ c.name }} <span class="muted small">{{ c.phone }}</span>
        </button>
      </div>
      <p v-else-if="courier" class="muted small">Aucun livreur actif. Créez-en un dans Back-office → Livreurs.</p>

      <template v-if="!courier">
        <div class="field"><label>Nom</label><input class="input" v-model="name" placeholder="Nom du client" /></div>
        <div class="field"><label>Téléphone</label><input class="input" v-model="phone" inputmode="tel" placeholder="+216 …" /></div>
      </template>
    </div>
    <template #foot>
      <button class="btn lg danger" v-if="initial?.name" @click="clear">Retirer</button>
      <button class="btn lg" @click="emit('close')">Annuler</button>
      <button v-if="!courier" class="btn lg primary" @click="emit('ok', { id: id, name: name.trim(), phone: phone.trim() })">Valider</button>
    </template>
  </Modal>
</template>

<style scoped>
.list { max-height: 46vh; overflow: auto; }
.btn.soft.on { border-color: var(--accent); background: var(--accent-soft); }
</style>
