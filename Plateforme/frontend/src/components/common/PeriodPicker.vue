<script setup>
import { isoDate, addDays, firstOfMonth, startOfWeek } from '../../utils/dates'
const props = defineProps({ from: String, to: String })
const emit = defineEmits(['update:from', 'update:to', 'change'])
const today = isoDate()
const presets = [
  { l: "Aujourd'hui", f: today, t: today }, { l: 'Hier', f: addDays(today, -1), t: addDays(today, -1) }, { l: '7 jours', f: addDays(today, -6), t: today },
  { l: 'Semaine', f: startOfWeek(today), t: today }, { l: 'Mois', f: firstOfMonth(today), t: today }, { l: '30 jours', f: addDays(today, -29), t: today }
]
function set(p) { emit('update:from', p.f); emit('update:to', p.t); emit('change') }
</script>
<template>
  <div class="row wrap gap-6">
    <button v-for="p in presets" :key="p.l" class="btn chip" :class="{ on: from===p.f && to===p.t }" @click="set(p)">{{ p.l }}</button>
    <input class="input" type="date" :value="from" @change="e => { emit('update:from', e.target.value); emit('change') }" style="width:auto;min-height:40px" />
    <span class="muted">→</span>
    <input class="input" type="date" :value="to" @change="e => { emit('update:to', e.target.value); emit('change') }" style="width:auto;min-height:40px" />
  </div>
</template>
