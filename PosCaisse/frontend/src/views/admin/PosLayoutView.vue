<script setup>
import { onMounted, ref } from 'vue'
import { api } from '../../api'
import { useUiStore } from '../../stores/ui'
import { useCatalogStore } from '../../stores/catalog'
import { useBusy } from '../../composables/useApi'
import { fmt } from '../../utils/money'
const ui = useUiStore(); const catalog = useCatalogStore(); const { busy, run } = useBusy()
const products = ref([]); const favorites = ref([]); const settings = ref({}); const cats = ref([]); const catFilter = ref('')
async function load() { try { products.value = await api.catalog.products(); cats.value = await api.catalog.categories(); settings.value = await api.admin.settings(); favorites.value = products.value.filter(p => p.favorite).sort((a, b) => a.favoriteOrder - b.favoriteOrder) } catch (e) { ui.error(e.humanMessage) } }
onMounted(load)
function addFav(p) { if (!favorites.value.some(f => f.id === p.id)) favorites.value.push(p) }
function move(list, i, d) { const j = i + d; if (j < 0 || j >= list.length) return; const a = list.splice(i, 1)[0]; list.splice(j, 0, a) }
async function saveFav() { if (await run(() => api.catalog.favorites(favorites.value.map(f => f.id)), { success: 'Favoris enregistrés' })) { catalog.load(true).catch(() => {}); load() } }
const inCat = () => products.value.filter(p => !catFilter.value || p.categoryId === Number(catFilter.value)).sort((a, b) => a.sortOrder - b.sortOrder)
async function saveOrder() { if (await run(() => api.catalog.reorderProducts(inCat().map(p => p.id)), { success: 'Ordre enregistré' })) { catalog.load(true).catch(() => {}); load() } }
function moveProduct(i, d) { const list = inCat(); const j = i + d; if (j < 0 || j >= list.length) return; const a = list[i].sortOrder; list[i].sortOrder = list[j].sortOrder; list[j].sortOrder = a; if (list[i].sortOrder === list[j].sortOrder) list[j].sortOrder += d }
async function saveSettings() { if (await run(() => api.admin.saveSettings({ 'pos.tileSize': settings.value['pos.tileSize'], 'pos.showImages': settings.value['pos.showImages'] }), { success: 'Affichage enregistré' })) catalog.load(true).catch(() => {}) }
</script>
<template>
  <div class="grid-2">
    <div class="card"><div class="card-title">⭐ Favoris (ordre d'affichage)</div>
      <p class="muted small">Les favoris apparaissent en premier sur le POS. Sélectionnez les produits les plus vendus.</p>
      <div class="col gap-4 mb-8"><div v-for="(f, i) in favorites" :key="f.id" class="row gap-6" style="padding:6px 8px;border:1px solid var(--border);border-radius:10px"><b class="grow">{{ i+1 }}. {{ f.name }}</b><span class="num muted">{{ fmt(f.price) }}</span><button class="btn sm icon" @click="move(favorites,i,-1)">↑</button><button class="btn sm icon" @click="move(favorites,i,1)">↓</button><button class="btn sm icon danger" @click="favorites.splice(i,1)">✕</button></div></div>
      <select class="input mb-8" @change="e => { const p = products.find(x => x.id===Number(e.target.value)); if (p) addFav(p); e.target.value='' }"><option value="">+ Ajouter un produit aux favoris…</option><option v-for="p in products.filter(p => p.active && !favorites.some(f=>f.id===p.id))" :key="p.id" :value="p.id">{{ p.name }} ({{ p.categoryName }})</option></select>
      <button class="btn primary" :disabled="busy" @click="saveFav">Enregistrer les favoris</button>
    </div>
    <div class="card"><div class="card-title">Affichage des tuiles</div>
      <div class="form-grid">
        <div class="field"><label>Taille des tuiles</label><select class="input" v-model="settings['pos.tileSize']"><option value="S">Petites (plus de produits)</option><option value="M">Moyennes</option><option value="L">Grandes (tactile 15")</option></select></div>
        <div class="field"><label>Images produits</label><select class="input" v-model="settings['pos.showImages']"><option value="true">Afficher</option><option value="false">Masquer</option></select></div>
      </div>
      <button class="btn primary mt-16" :disabled="busy" @click="saveSettings">Enregistrer</button>
      <div class="card-title mt-16">Ordre des produits par catégorie</div>
      <select class="input mb-8" v-model="catFilter"><option value="">Choisir une catégorie…</option><option v-for="c in cats" :key="c.id" :value="c.id">{{ c.name }}</option></select>
      <div v-if="catFilter" class="col gap-4 mb-8"><div v-for="(p, i) in inCat()" :key="p.id" class="row gap-6" style="padding:6px 8px;border:1px solid var(--border);border-radius:10px"><span class="grow">{{ p.name }}</span><button class="btn sm icon" @click="moveProduct(i,-1)">↑</button><button class="btn sm icon" @click="moveProduct(i,1)">↓</button></div><button class="btn primary" :disabled="busy" @click="saveOrder">Enregistrer l'ordre</button></div>
      <p class="muted small">L'ordre des catégories se règle dans « Catégories ».</p>
    </div>
  </div>
</template>
