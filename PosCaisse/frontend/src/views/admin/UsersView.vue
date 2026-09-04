<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import { fmtDateTime } from '../../utils/dates'
import Modal from '../../components/common/Modal.vue'
const ui = useUiStore(); const { busy, run } = useBusy()
const rows = ref([]); const roles = ref([]); const pos = ref([]); const edit = ref(null)
const COLORS = ['#f97316', '#0ea5e9', '#22c55e', '#ec4899', '#8b5cf6', '#eab308', '#ef4444', '#64748b']
async function load() { try { [rows.value, roles.value, pos.value] = await Promise.all([api.admin.users(), api.admin.roles(), api.admin.pointsOfSale()]) } catch (e) { ui.error(e.humanMessage) } }
onMounted(load)
function create() { edit.value = { username: '', fullName: '', roleId: roles.value.find(r => r.code === 'CASHIER')?.id || roles.value[0]?.id, pointOfSaleId: null, maxDiscountPercent: null, color: COLORS[rows.value.length % COLORS.length], active: true, password: '', pin: '' } }
function open(u) { edit.value = { ...u, password: '', pin: '' } }
async function save() {
  const b = { ...edit.value, maxDiscountPercent: edit.value.maxDiscountPercent === '' || edit.value.maxDiscountPercent === null ? null : Number(edit.value.maxDiscountPercent), password: edit.value.password || null, pin: edit.value.pin || null }
  const r = await run(() => api.admin.saveUser(edit.value.id, b), { success: 'Utilisateur enregistré' }); if (r) { edit.value = null; load() }
}
async function remove(u) { if (!await ui.confirm({ title: 'Supprimer', message: `Supprimer ${u.fullName} ?`, okLabel: 'Supprimer', danger: true })) return; if (await run(() => api.admin.deleteUser(u.id), { success: 'Supprimé' })) load() }
</script>
<template>
  <div class="toolbar"><button class="btn primary" @click="create">+ Nouvel utilisateur</button><span class="muted small">Les caissiers se connectent par PIN (4 à 8 chiffres). Le mot de passe sert à l'administration.</span></div>
  <div class="table-wrap"><table class="table"><thead><tr><th>Utilisateur</th><th>Identifiant</th><th>Rôle</th><th>Point de vente</th><th>Remise max</th><th>PIN</th><th>Mot de passe</th><th>Dernière connexion</th><th>Actif</th><th></th></tr></thead>
    <tbody><tr v-for="u in rows" :key="u.id" :style="{ opacity: u.active ? 1 : .5 }"><td><span class="color-dot" :style="{ background: u.color || '#64748b' }"></span><b>{{ u.fullName }}</b></td><td>{{ u.username }}</td><td><span class="badge" :class="u.roleCode==='ADMIN' ? 'accent' : u.roleCode==='MANAGER' ? 'info' : ''">{{ u.roleName }}</span></td><td>{{ pos.find(p=>p.id===u.pointOfSaleId)?.name || 'Tous' }}</td><td>{{ u.maxDiscountPercent !== null ? u.maxDiscountPercent + ' %' : '—' }}</td><td>{{ u.hasPin ? '✓' : '—' }}</td><td>{{ u.hasPassword ? '✓' : '—' }}</td><td class="small">{{ fmtDateTime(u.lastLoginAt) }}</td><td><span class="badge" :class="u.active ? 'success' : 'danger'">{{ u.active ? 'Oui' : 'Non' }}</span></td>
      <td class="actions"><button class="btn sm" @click="open(u)">Modifier</button> <button class="btn sm danger" @click="remove(u)">✕</button></td></tr></tbody></table></div>
  <Modal v-if="edit" size="md" :title="edit.id ? 'Modifier ' + edit.fullName : 'Nouvel utilisateur'" @close="edit=null">
    <div class="form-grid">
      <div class="field"><label>Nom complet</label><input class="input" v-model="edit.fullName" autofocus /></div>
      <div class="field"><label>Identifiant</label><input class="input" v-model="edit.username" /></div>
      <div class="field"><label>Rôle</label><select class="input" v-model="edit.roleId"><option v-for="r in roles" :key="r.id" :value="r.id">{{ r.name }}</option></select></div>
      <div class="field"><label>Point de vente</label><select class="input" v-model="edit.pointOfSaleId"><option :value="null">Tous</option><option v-for="p in pos" :key="p.id" :value="p.id">{{ p.name }}</option></select></div>
      <div class="field"><label>PIN {{ edit.id ? '(laisser vide pour conserver)' : '' }}</label><input class="input" v-model="edit.pin" inputmode="numeric" maxlength="8" placeholder="4 à 8 chiffres" /></div>
      <div class="field"><label>Mot de passe {{ edit.id ? '(laisser vide pour conserver)' : '' }}</label><input class="input" type="password" v-model="edit.password" autocomplete="new-password" /></div>
      <div class="field"><label>Remise max autorisée (%)</label><input class="input" v-model="edit.maxDiscountPercent" inputmode="decimal" placeholder="vide = selon rôle" /></div>
      <div class="field"><label>Couleur</label><div class="row wrap gap-6"><button v-for="c in COLORS" :key="c" class="sw" :class="{ on: edit.color===c }" :style="{ background: c }" @click="edit.color=c"></button></div></div>
      <label class="check"><input type="checkbox" v-model="edit.active" /> Compte actif</label>
    </div>
    <template #foot><button class="btn lg" @click="edit=null">Annuler</button><button class="btn lg primary" :disabled="busy || !edit.fullName || !edit.username" @click="save">Enregistrer</button></template>
  </Modal>
</template>
<style scoped>.sw { width: 34px; height: 34px; border-radius: 50%; border: 3px solid transparent; } .sw.on { border-color: #0f172a; }</style>
