/** Navigateur réel, serveur local, API simulée : aucun accès à une caisse en service. */
import { readFile } from 'node:fs/promises'
import { resolve } from 'node:path'
import { createServer } from 'vite'
import vue from '@vitejs/plugin-vue'
import { chromium } from 'playwright'

export async function demarrerInterface() {
  const server = await createServer({
    configFile: false, root: resolve(import.meta.dirname, '..'), plugins: [vue()],
    server: { host: '127.0.0.1', port: 0 }, logLevel: 'error'
  })
  await server.listen()
  const browser = await chromium.launch({ headless: true,
    ...(process.env.PLAYWRIGHT_CHANNEL ? { channel: process.env.PLAYWRIGHT_CHANNEL } : {}) })
  return { browser, url: server.resolvedUrls.local[0],
    fermer: async () => { await browser.close(); await server.close() } }
}

export async function ouvrirCaisse(infra, { carte = 'superette-el-baraka', width = 1366, height = 768 } = {}) {
  const source = JSON.parse(await readFile(resolve(import.meta.dirname, '../../catalogs', carte + '.json'), 'utf8'))
  const categories = source.categories.map((c, i) => ({ ...c, id: i + 1 }))
  const produits = source.products.map((p, i) => ({ ...p, id: i + 1, available: true,
    categoryId: categories.find(c => c.name === p.category).id, categoryName: p.category,
    productType: 'SIMPLE', modifierGroups: [], menuComponents: [], variantPrices: [],
    unite: p.unite || 'PIECE' }))
  const cafe = carte === 'mistral-coffee'
  const catalogue = { categories, products: produits, variants: [], ingredients: source.ingredients || [],
    kitchenNotes: [], company: { name: source.label, decimals: 3, currencySymbol: 'DT' },
    paymentMethods: [{ id: 1, kind: 'CASH', name: 'Espèces' }, { id: 2, kind: 'CARD', name: 'Carte' }],
    settings: { 'pos.serviceModes': cafe ? 'DINE_IN,TAKEAWAY' : 'TAKEAWAY',
      'pos.defaultServiceMode': cafe ? 'DINE_IN' : 'TAKEAWAY', 'pos.tileSize': cafe ? 'M' : 'S',
      'pos.quickCash': cafe ? '1,2,5,10' : '5,10,20,50', 'stock.mode': 'total' } }
  const context = await infra.browser.newContext({ viewport: { width, height } })
  await context.addInitScript(() => localStorage.setItem('poscaisse.token', 'jeton-simule-local'))
  const appels = []; const erreurs = []
  const page = await context.newPage()
  page.on('pageerror', error => erreurs.push(error.message))
  await page.route('**/*', async route => {
    const req = route.request(); const url = new URL(req.url())
    // Même les images du catalogue ne doivent jamais ouvrir une URL externe.
    if (url.origin !== new URL(infra.url).origin) return route.abort()
    if (!url.pathname.startsWith('/api/')) return route.continue()
    appels.push({ path: url.pathname, method: req.method(), body: req.postDataJSON() })
    let body = []
    if (url.pathname === '/api/auth/me') body = {
      user: { id: 1, fullName: 'Audit local', roleName: 'Caissier', permissions: ['SELL', 'LINE_DELETE', 'DISCOUNT_APPLY', 'PRICE_EDIT', 'CASH_MOVEMENT'] },
      openSession: { id: 1, registerId: 1, registerName: 'CAISSE AUDIT', pointOfSaleId: 1 }
    }
    if (url.pathname === '/api/pos/catalog') body = catalogue
    if (url.pathname === '/api/pos/stock') body = { lines: [] }
    if (url.pathname === '/api/customers') body = [{ id: 8, name: 'Client à choisir', phone: '' }]
    if (url.pathname === '/api/pos/checkout') body = { id: 1, ticketNumber: 'AUDIT-1', total: 1, change: 0, printJobs: [] }
    await route.fulfill({ contentType: 'application/json', body: JSON.stringify(body) })
  })
  await page.goto(infra.url + 'pos')
  await page.locator('.tile').first().waitFor()
  return { page, context, appels, erreurs, catalogue }
}

export const encaissements = etat => etat.appels.filter(a => a.path === '/api/pos/checkout')

export async function ouvrirPaiement(etat) {
  await etat.page.locator('.tile').first().click()
  await etat.page.locator('.cart .pay').click()
  await etat.page.getByRole('button', { name: 'Valider et imprimer' }).waitFor()
}
