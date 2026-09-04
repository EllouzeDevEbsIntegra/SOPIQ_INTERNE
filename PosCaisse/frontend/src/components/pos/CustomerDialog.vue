<script setup>
import { ref, watch } from 'vue'
import Modal from '../common/Modal.vue'
import { api } from '../../api'
const props = defineProps({ initial: Object })
const emit = defineEmits(['close', 'ok'])
const name = ref(props.initial?.name || ''); const phone = ref(props.initial?.phone || ''); const id = ref(props.initial?.id || null)
const q = ref(''); const results = ref([]); let t = null
watch(q, v => { clearTimeout(t); t = setTimeout(async () => { results.value = v.trim() ? await api.admin.customers(v).catch(() => []) : [] }, 250) })
function pick(c) { id.value = c.id; name.value = c.name; phone.value = c.phone || ''; results.value = []; q.value = '' }
function clear() { emit('ok', { id: null, name: '', phone: '' }) }
</script>
<template>
  <Modal title="Client (facultatif)" @close="emit('close')">
    <div class="col gap-16">
      <div class="field"><label>Rechercher un client existant</label><input class="input" v-model="q" placeholder="Nom ou téléphone…" /></div>
      <div v-if="results.length" class="col gap-4"><button v-for="c in results" :key="c.id" class="btn soft" style="justify-content:flex-start" @click="pick(c)">{{ c.name }} <span class="muted small">{{ c.phone }}</span></button></div>
      <div class="field"><label>Nom</label><input class="input" v-model="name" placeholder="Nom du client" /></div>
      <div class="field"><label>Téléphone</label><input class="input" v-model="phone" inputmode="tel" placeholder="+216 …" /></div>
    </div>
    <template #foot>
      <button class="btn lg danger" v-if="initial?.name" @click="clear">Retirer</button>
      <button class="btn lg" @click="emit('close')">Annuler</button>
      <button class="btn lg primary" @click="emit('ok', { id: id, name: name.trim(), phone: phone.trim() })">Valider</button>
    </template>
  </Modal>
</template>
