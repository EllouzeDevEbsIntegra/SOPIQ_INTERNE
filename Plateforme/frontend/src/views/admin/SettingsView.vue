<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useCatalogStore } from '../../stores/catalog'
import { useBusy } from '../../composables/useApi'
const ui = useUiStore(); const catalog = useCatalogStore(); const { busy, run } = useBusy()
const s = ref(null); const modes = ref({ DINE_IN: true, TAKEAWAY: true, DELIVERY: true })
onMounted(async () => { try { s.value = await api.admin.settings(); const on = (s.value['pos.serviceModes'] || '').split(','); for (const k of Object.keys(modes.value)) modes.value[k] = on.includes(k) } catch (e) { ui.error(e.humanMessage) } })
async function save() {
  const enabled = Object.keys(modes.value).filter(k => modes.value[k])
  if (!enabled.length) return ui.error('Activez au moins un mode de service.')
  if (!enabled.includes(s.value['pos.defaultServiceMode'])) s.value['pos.defaultServiceMode'] = enabled[0]
  s.value['pos.serviceModes'] = enabled.join(',')
  const r = await run(() => api.admin.saveSettings(s.value), { success: 'Paramètres enregistrés' }); if (r) { s.value = r; catalog.load(true).catch(() => {}) }
}
</script>
<template>
  <div v-if="s" class="grid-2">
    <div class="card"><div class="card-title">Vente</div>
      <div class="form-grid">
        <div class="field span-2"><label>Modes de service activés</label><div class="row wrap gap-16"><label class="check"><input type="checkbox" v-model="modes.DINE_IN" /> Sur place</label><label class="check"><input type="checkbox" v-model="modes.TAKEAWAY" /> À emporter</label><label class="check"><input type="checkbox" v-model="modes.DELIVERY" /> Livraison</label></div></div>
        <div class="field"><label>Mode par défaut</label><select class="input" v-model="s['pos.defaultServiceMode']"><option value="DINE_IN">Sur place</option><option value="TAKEAWAY">À emporter</option><option value="DELIVERY">Livraison</option></select></div>
        <div class="field"><label>Seuil de remise nécessitant un manager (%)</label><input class="input" v-model="s['discount.highThresholdPercent']" inputmode="decimal" /></div>
        <div class="field"><label>Boutons espèces rapides (séparés par des virgules)</label><input class="input" v-model="s['pos.quickCash']" placeholder="5,10,20,50" /></div>
        <!-- Une estimation de gestion, pas une comptabilite : la caisse connait ce qui a
             ete vendu, pas ce que les ingredients ont coute. A 0, la ligne ne s'affiche
             nulle part - mieux vaut rien qu'un taux invente. -->
        <div class="field"><label>Marge bénéficiaire (%)</label><input class="input" v-model="s['finance.marginPercent']" inputmode="decimal" placeholder="0" /><div class="tiny muted">Applique au chiffre d'affaires de la session pour afficher un bénéfice estimé sur l'écran de clôture et sur l'état de caisse. 0 = ne rien afficher.</div></div>
        <div class="field"><label>TVA</label><select class="input" v-model="s['tax.enabled']"><option value="false">Désactivée (prix TTC simples)</option><option value="true">Activée (TVA calculée dans le prix TTC)</option></select></div>
      </div>
    </div>
    <div class="card"><div class="card-title">Numérotation & impression</div>
      <div class="form-grid">
        <!-- La numerotation a son propre ecran : le format seul ne disait pas quand le
             compteur repart a 1, et c'est cette question-la qu'on se pose. -->
        <div class="field span-2"><label>Numérotation des tickets</label><router-link class="btn" to="/admin/ticket-numbering">Format et remise à zéro du compteur</router-link><div class="tiny muted">Format imprimé, remise à zéro (journalière, mensuelle, annuelle ou continue), compteur par point de vente ou par caisse, et le prochain numéro.</div></div>
        <div class="field"><label>Écran de connexion</label><select class="input" v-model="s['auth.showUserTiles']"><option value="true">Afficher les tuiles caissiers</option><option value="false">PIN seul</option></select></div>
      </div>
    </div>
    <!--
        LE METIER.

        Ces quatre reglages font la difference entre une caisse de restaurant et une
        caisse de boutique. Ils ne sont reserves a aucun metier : un cafe qui veut
        scanner ses bouteilles coche la premiere case et cela marche.
    -->
    <div class="card" style="grid-column:1/-1"><div class="card-title">Métier — code-barres et stock</div>
      <div class="form-grid">
        <div class="field">
          <label>Code-barres</label>
          <select class="input" v-model="s['catalog.barcode.enabled']">
            <option value="false">Non utilisé</option>
            <option value="true">Activé — scan en caisse, champ sur la fiche article</option>
          </select>
          <div class="tiny muted">Le lecteur est un clavier : rien à installer. Il tape le code puis Entrée, et la caisse le reconnaît à sa vitesse de frappe.</div>
        </div>
        <div class="field">
          <label>Que compte-t-on ?</label>
          <select class="input" v-model="s['stock.mode']">
            <option value="aucun">Rien — aucun stock n'est suivi</option>
            <option value="partiel">Certains articles — chaque fiche décide</option>
            <option value="total">Tous les articles</option>
          </select>
          <div class="tiny muted">« Certains » est le cas courant : la boutique suit ses recharges et pas ses sacs plastique.</div>
        </div>
        <div class="field">
          <label>Quand il n'y en a plus</label>
          <select class="input" v-model="s['stock.rupture']">
            <option value="refuser">Refuser la vente</option>
            <option value="avertir">Avertir, mais laisser vendre</option>
            <option value="passer">Ne rien dire</option>
          </select>
          <div class="tiny muted">Un fast-food refuse : il ne peut pas servir ce qu'il n'a pas. Une boutique préfère parfois vendre et régulariser le soir.</div>
        </div>
        <div class="field">
          <label>Comment le stock entre</label>
          <select class="input" v-model="s['stock.entree']">
            <option value="libre">Saisie libre</option>
            <option value="achat">Par un achat — fournisseur et prix d'achat</option>
          </select>
          <div class="tiny muted">L'achat garde le prix payé sur chaque entrée : c'est lui qui donne la marge réelle, pas le dernier prix connu de la fiche.</div>
        </div>
      </div>
    </div>

    <div style="grid-column:1/-1"><button class="btn primary lg" :disabled="busy" @click="save">Enregistrer les paramètres</button></div>
  </div>
</template>
