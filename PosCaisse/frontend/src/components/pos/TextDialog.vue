<script setup>
import { ref } from 'vue'
import Modal from '../common/Modal.vue'
const props = defineProps({ title: String, initial: String, placeholder: String, label: String, required: Boolean, suggestions: Array })
const emit = defineEmits(['close', 'ok'])
const value = ref(props.initial || '')
</script>
<template>
  <Modal :title="title" @close="emit('close')">
    <div class="row wrap gap-8 mb-8" v-if="suggestions?.length"><button v-for="s in suggestions" :key="s" class="btn chip" @click="value = s">{{ s }}</button></div>
    <div class="field"><label v-if="label">{{ label }}</label><textarea class="input" v-model="value" :placeholder="placeholder" autofocus></textarea></div>
    <template #foot>
      <button class="btn lg" @click="emit('close')">Annuler</button>
      <button class="btn lg primary" :disabled="required && !value.trim()" @click="emit('ok', value.trim())">Valider</button>
    </template>
  </Modal>
</template>
