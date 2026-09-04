<script setup>
import { onMounted, ref, watch } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useBusy } from '../../composables/useApi'
import Modal from '../../components/common/Modal.vue'
const ui = useUiStore(); const { busy, run } = useBusy()
const tab = ref('template'); const dests = ref([]); const editDest = ref(null); const tpl = ref(null); const preview = ref(null); let timer = null
const flags = [
  ['showCompanyName', 'Nom commercial'], ['showAddress', 'Adresse'], ['showPhone', 'Téléphone'], ['showTaxId', 'Matricule fiscal'], ['showTicketNumber', 'N° de ticket'], ['showDate', 'Date'], ['showTime', 'Heure'],
  ['showCashier', 'Caissier'], ['showRegister', 'Caisse'], ['showServiceMode', 'Mode de service'], ['showCustomer', 'Client'], ['showItemCount', "Nombre d'articles"], ['showUnitPrice', 'Prix unitaire'], ['showModifiers', 'Options / suppléments'],
  ['showDiscounts', 'Remises'], ['showSubtotal', 'Sous-total'], ['showTaxes', 'TVA (si activée)'], ['showPayments', 'Paiements'], ['showChange', 'Monnaie rendue'], ['showDuplicateLabel', 'Mention DUPLICATA'], ['prepShowTime', 'Heure sur tickets préparation']
]
async function load() { try { dests.value = await api.admin.destinations(); const list = await api.admin.templates(); tpl.value = list.find(t => t.code === 'DEFAULT') || list[0]; refresh() } catch (e) { ui.error(e.humanMessage) } }
onMounted(load)
async function refresh() { if (!tpl.value) return; try { preview.value = await api.admin.previewReceipt(tpl.value) } catch (e) { ui.error(e.humanMessage) } }
watch(tpl, () => { clearTimeout(timer); timer = setTimeout(refresh, 400) }, { deep: true })
async function saveTpl() { await run(() => api.admin.saveTemplate(tpl.value.code, tpl.value), { success: 'Modèle de ticket enregistré' }) }
async function saveDest() { const r = await run(() => api.admin.saveDestination(editDest.value.id, editDest.value), { success: 'Destination enregistrée' }); if (r) { editDest.value = null; load() } }
async function removeDest(d) { if (!await ui.confirm({ title: 'Supprimer', message: `Supprimer la destination ${d.name} ?`, okLabel: 'Supprimer', danger: true })) return; if (await run(() => api.admin.deleteDestination(d.id), { success: 'Supprimée' })) load() }
</script>
<template>
  <div class="tabs"><button :class="{ on: tab==='template' }" @click="tab='template'">Modèle de ticket</button><button :class="{ on: tab==='dest' }" @click="tab='dest'">Destinations & copies</button></div>
  <div v-if="tab==='template' && tpl" class="grid-2">
    <div class="card">
      <div class="form-grid">
        <div class="field"><label>Largeur papier</label><select class="input" v-model.number="tpl.paperWidth"><option :value="80">80 mm</option><option :value="58">58 mm</option></select></div>
        <div class="field"><label>Taille de police (px)</label><input class="input" type="number" min="8" max="20" v-model.number="tpl.fontSize" /></div>
        <div class="field"><label>Marges (mm)</label><input class="input" type="number" min="0" max="15" v-model.number="tpl.marginMm" /></div>
        <div class="field"><label>Séparateur</label><select class="input" v-model="tpl.config.separator"><option value="-">- - - -</option><option value="=">= = = =</option><option value="_">_ _ _ _</option><option value="·">· · · ·</option></select></div>
        <label class="check"><input type="checkbox" v-model="tpl.showLogo" /> Logo (défini dans Entreprise)</label>
        <div class="field span-2"><label>Texte d'en-tête supplémentaire</label><textarea class="input" v-model="tpl.headerText" rows="2"></textarea></div>
        <div class="field span-2"><label>Texte de pied (ex. Merci pour votre visite)</label><textarea class="input" v-model="tpl.footerText" rows="2"></textarea></div>
      </div>
      <div class="section-title">Informations affichées</div>
      <div class="flags"><label v-for="[k, l] in flags" :key="k" class="check"><input type="checkbox" v-model="tpl.config[k]" />{{ l }}</label></div>
      <button class="btn primary mt-16" :disabled="busy" @click="saveTpl">Enregistrer le modèle</button>
    </div>
    <div class="card" style="background:#e2e8f0"><div class="card-title">Aperçu (dernière vente)</div>
      <div v-if="preview" style="display:flex;justify-content:center"><div class="receipt-paper" :style="{ width: (preview.paperWidth <= 58 ? 220 : 300) + 'px', fontSize: preview.fontSize + 'px' }"><img v-if="preview.showLogo && preview.logoData" :src="preview.logoData" style="max-width:60%;display:block;margin:0 auto 6px" /><pre style="margin:0;font:inherit">{{ preview.content }}</pre></div></div>
    </div>
  </div>
  <div v-if="tab==='dest'">
    <div class="toolbar"><button class="btn primary" @click="editDest={ code: '', name: '', kind: 'PREP', copies: 1, showPrices: false, sortOrder: dests.length, active: true }">+ Nouvelle destination</button><span class="muted small">Chaque vente produit un ticket par destination concernée (produits/catégories associés). 0 copie = pas d'impression.</span></div>
    <div class="table-wrap"><table class="table"><thead><tr><th>Code</th><th>Nom</th><th>Type</th><th>Copies</th><th>Prix affichés</th><th>Actif</th><th></th></tr></thead>
      <tbody><tr v-for="d in dests" :key="d.id"><td>{{ d.code }}</td><td><b>{{ d.name }}</b></td><td><span class="badge" :class="d.kind==='CUSTOMER' ? 'accent' : 'info'">{{ d.kind==='CUSTOMER' ? 'Ticket client' : 'Préparation' }}</span></td><td><b>{{ d.copies }}</b></td><td>{{ d.showPrices ? '✓' : '—' }}</td><td><span class="badge" :class="d.active ? 'success' : 'danger'">{{ d.active ? 'Oui' : 'Non' }}</span></td><td class="actions"><button class="btn sm" @click="editDest={...d}">Modifier</button> <button class="btn sm danger" @click="removeDest(d)">✕</button></td></tr></tbody></table></div>
  </div>
  <Modal v-if="editDest" :title="editDest.id ? 'Destination ' + editDest.name : 'Nouvelle destination'" @close="editDest=null">
    <div class="form-grid"><div class="field"><label>Code</label><input class="input" v-model="editDest.code" placeholder="GRILL" /></div><div class="field"><label>Nom</label><input class="input" v-model="editDest.name" placeholder="Grill" /></div><div class="field"><label>Type</label><select class="input" v-model="editDest.kind"><option value="PREP">Préparation (cuisine, bar…)</option><option value="CUSTOMER">Ticket client</option></select></div><div class="field"><label>Nombre de copies</label><input class="input" type="number" min="0" max="5" v-model.number="editDest.copies" /></div><label class="check"><input type="checkbox" v-model="editDest.showPrices" /> Afficher les prix</label><label class="check"><input type="checkbox" v-model="editDest.active" /> Active</label></div>
    <template #foot><button class="btn lg" @click="editDest=null">Annuler</button><button class="btn lg primary" :disabled="busy || !editDest.name || !editDest.code" @click="saveDest">Enregistrer</button></template>
  </Modal>
</template>
<style scoped>.flags { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 0 12px; }</style>
