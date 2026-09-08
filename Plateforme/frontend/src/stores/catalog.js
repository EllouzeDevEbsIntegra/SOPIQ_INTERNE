import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { api } from '../api'
import { configureMoney } from '../utils/money'

export const useCatalogStore = defineStore('catalog', () => {
  const categories = ref([])
  const products = ref([])
  const paymentMethods = ref([])
  const kitchenNotes = ref([])   // remarques de cuisine proposees sur une ligne
  const variants = ref([])       // axes de declinaison : Taille, Pate, Format
  const ingredients = ref([])    // mots composant le nom des articles
  const settings = ref({})
  const company = ref(null)
  const loaded = ref(false)
  const loading = ref(false)

  async function load(force = false) {
    if (loaded.value && !force) return
    loading.value = true
    try {
      const c = await api.pos.catalog()
      categories.value = c.categories; products.value = c.products; paymentMethods.value = c.paymentMethods
      settings.value = c.settings || {}; company.value = c.company; kitchenNotes.value = c.kitchenNotes || []
      variants.value = c.variants || []; ingredients.value = c.ingredients || []
      if (c.company) configureMoney({ decimals: c.company.decimals, symbol: c.company.currencySymbol })
      loaded.value = true
    } finally { loading.value = false }
  }
  const productsById = computed(() => Object.fromEntries(products.value.map(p => [p.id, p])))
  const favorites = computed(() => products.value.filter(p => p.favorite).sort((a, b) => a.favoriteOrder - b.favoriteOrder))
  const byCategory = (catId) => products.value.filter(p => p.categoryId === catId)
  const setting = (k, def) => settings.value[k] ?? def
  const serviceModes = computed(() => (setting('pos.serviceModes', 'DINE_IN,TAKEAWAY,DELIVERY')).split(',').map(s => s.trim()).filter(Boolean))
  const quickCash = computed(() => (setting('pos.quickCash', '5,10,20,50')).split(',').map(Number).filter(n => n > 0))
  const cashMethod = computed(() => paymentMethods.value.find(m => m.kind === 'CASH'))
  function updateProduct(p) { const i = products.value.findIndex(x => x.id === p.id); if (i >= 0) products.value[i] = p }
  function search(q) {
    const s = (q || '').trim().toLowerCase()
    if (!s) return []
    return products.value.filter(p => p.name.toLowerCase().includes(s) || (p.code || '').toLowerCase().includes(s) || (p.reference || '').toLowerCase().includes(s) || (p.shortName || '').toLowerCase().includes(s) || (p.barcode || '').includes(s)).slice(0, 40)
  }

  /**
   * L'article que le lecteur vient de scanner — ou rien.
   *
   * Le code est compare TEL QUEL : un code-barres n'a ni casse ni accent, et l'accepter
   * a peu pres reviendrait a vendre un article pour un autre. Le lecteur tape le code
   * puis Entree, exactement comme un clavier : c'est pour ca que rien n'a besoin d'etre
   * installe pour qu'il fonctionne.
   */
  function parCodeBarres(code) {
    const c = (code || '').trim()
    if (!c) return null
    return products.value.find(p => p.barcode && p.barcode === c) || null
  }

  return { categories, products, paymentMethods, settings, company, loaded, loading, load, productsById, favorites, byCategory, setting, serviceModes, kitchenNotes, quickCash, cashMethod, updateProduct, search, parCodeBarres, variants, ingredients }
})
