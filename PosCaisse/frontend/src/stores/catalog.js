import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { api } from '../api'
import { configureMoney } from '../utils/money'

export const useCatalogStore = defineStore('catalog', () => {
  const categories = ref([])
  const products = ref([])
  const paymentMethods = ref([])
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
      settings.value = c.settings || {}; company.value = c.company
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
    return products.value.filter(p => p.name.toLowerCase().includes(s) || (p.code || '').toLowerCase().includes(s) || (p.reference || '').toLowerCase().includes(s) || (p.shortName || '').toLowerCase().includes(s)).slice(0, 40)
  }
  return { categories, products, paymentMethods, settings, company, loaded, loading, load, productsById, favorites, byCategory, setting, serviceModes, quickCash, cashMethod, updateProduct, search }
})
