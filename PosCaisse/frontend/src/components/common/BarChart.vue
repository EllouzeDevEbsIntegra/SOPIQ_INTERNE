<script setup>
/** Dependency-free horizontal/vertical bar chart driven by [{label, value}] */
import { computed } from 'vue'
import { fmt } from '../../utils/money'
const props = defineProps({ data: Array, labelKey: { type: String, default: 'label' }, valueKey: { type: String, default: 'value' }, vertical: Boolean, money: { type: Boolean, default: true }, color: { type: String, default: 'var(--accent)' }, colorKey: String, max: { type: Number, default: 12 } })
const rows = computed(() => (props.data || []).slice(0, props.max))
const top = computed(() => Math.max(1, ...rows.value.map(r => Number(r[props.valueKey]) || 0)))
const f = (v) => props.money ? fmt(v) : String(v)
</script>
<template>
  <div v-if="!rows.length" class="empty">Aucune donnée</div>
  <div v-else-if="vertical" class="vbars">
    <div v-for="(r, i) in rows" :key="i" class="vb" :title="r[labelKey] + ' : ' + f(r[valueKey])">
      <div class="vval tiny num">{{ f(r[valueKey]) }}</div>
      <div class="vbar" :style="{ height: Math.max(2, 100 * (Number(r[valueKey]) || 0) / top) + '%', background: colorKey && r[colorKey] ? r[colorKey] : color }"></div>
      <div class="vlab tiny">{{ r[labelKey] }}</div>
    </div>
  </div>
  <div v-else class="hbars">
    <div v-for="(r, i) in rows" :key="i" class="hb">
      <div class="row between small"><span class="grow" style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap"><span v-if="colorKey && r[colorKey]" class="color-dot" :style="{ background: r[colorKey] }"></span>{{ r[labelKey] }}</span><b class="num">{{ f(r[valueKey]) }}</b></div>
      <div class="bar"><i :style="{ width: 100 * (Number(r[valueKey]) || 0) / top + '%', background: colorKey && r[colorKey] ? r[colorKey] : color }"></i></div>
    </div>
  </div>
</template>
<style scoped>
.hbars { display: flex; flex-direction: column; gap: 8px; }
.vbars { display: flex; align-items: flex-end; gap: 6px; height: 200px; padding-top: 18px; }
.vb { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: flex-end; height: 100%; min-width: 0; }
.vbar { width: 100%; border-radius: 6px 6px 0 0; min-height: 2px; }
.vval { margin-bottom: 4px; white-space: nowrap; } .vlab { margin-top: 4px; color: var(--text-2); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 100%; }
</style>
