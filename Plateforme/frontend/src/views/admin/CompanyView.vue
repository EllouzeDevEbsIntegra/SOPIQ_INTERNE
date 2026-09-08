<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useCatalogStore } from '../../stores/catalog'
import { useBusy } from '../../composables/useApi'
import Modal from '../../components/common/Modal.vue'
const ui = useUiStore(); const catalog = useCatalogStore(); const { busy, run } = useBusy()
const company = ref(null); const pos = ref([]); const registers = ref([]); const editPos = ref(null); const editReg = ref(null)
async function load() { try { [company.value, pos.value, registers.value] = await Promise.all([api.admin.company(), api.admin.pointsOfSale(), api.admin.registers()]) } catch (e) { ui.error(e.humanMessage) } }
onMounted(load)
async function saveCompany() { const r = await run(() => api.admin.saveCompany(company.value), { success: 'Entreprise enregistrée' }); if (r) { company.value = r; catalog.load(true).catch(() => {}) } }
function onLogo(e) { const f = e.target.files[0]; if (!f) return; if (f.size > 300 * 1024) return ui.error('Logo trop lourd (max 300 Ko).'); const r = new FileReader(); r.onload = () => { company.value.logoData = r.result }; r.readAsDataURL(f) }
async function savePos() { const r = await run(() => api.admin.savePos(editPos.value.id, editPos.value), { success: 'Point de vente enregistré' }); if (r) { editPos.value = null; load() } }
async function saveReg() { const r = await run(() => api.admin.saveRegister(editReg.value.id, editReg.value), { success: 'Caisse enregistrée' }); if (r) { editReg.value = null; load() } }
</script>
<template>
  <div v-if="company" class="grid-2">
    <div class="card" style="grid-column:1/-1"><div class="card-title">Entreprise</div>
      <div class="form-grid">
        <div class="field"><label>Raison sociale</label><input class="input" v-model="company.name" /></div><div class="field"><label>Nom commercial (ticket)</label><input class="input" v-model="company.tradeName" /></div>
        <div class="field span-2"><label>Adresse</label><input class="input" v-model="company.address" /></div>
        <div class="field"><label>Téléphone</label><input class="input" v-model="company.phone" /></div><div class="field"><label>Matricule fiscal</label><input class="input" v-model="company.taxId" /></div>
        <div class="field"><label>Devise</label><input class="input" v-model="company.currency" maxlength="3" /></div><div class="field"><label>Symbole</label><input class="input" v-model="company.currencySymbol" /></div>
        <div class="field"><label>Décimales</label><select class="input" v-model.number="company.decimals"><option :value="3">3 (TND)</option><option :value="2">2</option><option :value="0">0</option></select></div><div class="field"><label>Fuseau horaire</label><input class="input" v-model="company.timezone" /></div>
        <div class="field span-2"><label>Logo (ticket)</label><div class="row"><img v-if="company.logoData" :src="company.logoData" style="max-height:60px;max-width:160px" /><input type="file" accept="image/*" @change="onLogo" /><button v-if="company.logoData" class="btn sm" @click="company.logoData=''">Retirer</button></div></div>
      </div>
      <button class="btn primary mt-16" :disabled="busy" @click="saveCompany">Enregistrer</button>
    </div>
    <div class="card"><div class="row between mb-8"><div class="card-title" style="margin:0">Points de vente</div><button class="btn sm primary" @click="editPos={ code: '', name: '', address: '', phone: '', active: true }">+ Ajouter</button></div>
      <table class="table"><thead><tr><th>Code</th><th>Nom</th><th>Caisses</th><th>Actif</th><th></th></tr></thead><tbody><tr v-for="p in pos" :key="p.id"><td>{{ p.code }}</td><td><b>{{ p.name }}</b><div class="tiny muted">{{ p.address }}</div></td><td>{{ p.registerCount }}</td><td>{{ p.active ? '✓' : '—' }}</td><td class="actions"><button class="btn sm" @click="editPos={...p}">Modifier</button></td></tr></tbody></table></div>
    <div class="card"><div class="row between mb-8"><div class="card-title" style="margin:0">Caisses / terminaux</div><button class="btn sm primary" @click="editReg={ code: '', name: '', pointOfSaleId: pos[0]?.id, active: true }">+ Ajouter</button></div>
      <table class="table"><thead><tr><th>Code</th><th>Nom</th><th>Point de vente</th><th>Actif</th><th></th></tr></thead><tbody><tr v-for="r in registers" :key="r.id"><td>{{ r.code }}</td><td><b>{{ r.name }}</b></td><td>{{ r.pointOfSaleName }}</td><td>{{ r.active ? '✓' : '—' }}</td><td class="actions"><button class="btn sm" @click="editReg={...r}">Modifier</button></td></tr></tbody></table></div>
  </div>
  <Modal v-if="editPos" :title="editPos.id ? 'Point de vente' : 'Nouveau point de vente'" @close="editPos=null">
    <div class="form-grid"><div class="field"><label>Code</label><input class="input" v-model="editPos.code" placeholder="PV02" /></div><div class="field"><label>Nom</label><input class="input" v-model="editPos.name" /></div><div class="field span-2"><label>Adresse</label><input class="input" v-model="editPos.address" /></div><div class="field"><label>Téléphone</label><input class="input" v-model="editPos.phone" /></div><label class="check"><input type="checkbox" v-model="editPos.active" /> Actif</label></div>
    <template #foot><button class="btn lg" @click="editPos=null">Annuler</button><button class="btn lg primary" :disabled="busy" @click="savePos">Enregistrer</button></template>
  </Modal>
  <Modal v-if="editReg" :title="editReg.id ? 'Caisse' : 'Nouvelle caisse'" @close="editReg=null">
    <div class="form-grid"><div class="field"><label>Code</label><input class="input" v-model="editReg.code" placeholder="C03" /></div><div class="field"><label>Nom</label><input class="input" v-model="editReg.name" placeholder="CAISSE 03" /></div><div class="field"><label>Point de vente</label><select class="input" v-model="editReg.pointOfSaleId"><option v-for="p in pos" :key="p.id" :value="p.id">{{ p.name }}</option></select></div><label class="check"><input type="checkbox" v-model="editReg.active" /> Active</label></div>
    <template #foot><button class="btn lg" @click="editReg=null">Annuler</button><button class="btn lg primary" :disabled="busy" @click="saveReg">Enregistrer</button></template>
  </Modal>
</template>
