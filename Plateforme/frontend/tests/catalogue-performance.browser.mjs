import { after, before, test } from 'node:test'
import assert from 'node:assert/strict'
import { demarrerInterface, ouvrirCaisse, ouvrirPaiement, encaissements } from './interface-fixture.mjs'

let infra
before(async () => { infra = await demarrerInterface() })
after(async () => { await infra?.fermer() })

const percentile = (valeurs, rang) => {
  const triees = [...valeurs].sort((a, b) => a - b)
  return triees[Math.max(0, Math.ceil(triees.length * rang) - 1)]
}

async function mesurerOuvertures(carte, repetitions = 10) {
  const durees = []
  for (let i = 0; i < repetitions; i++) {
    const depart = performance.now()
    const etat = await ouvrirCaisse(infra, { carte })
    durees.push(performance.now() - depart)
    await etat.context.close()
  }
  return { mediane: percentile(durees, .5), p95: percentile(durees, .95) }
}

async function mesurerEncaissements(carte, repetitions = 10) {
  const etat = await ouvrirCaisse(infra, { carte })
  const durees = []
  try {
    for (let i = 0; i < repetitions; i++) {
      const avant = encaissements(etat).length
      const depart = performance.now()
      await ouvrirPaiement(etat)
      await etat.page.getByRole('button', { name: 'Valider et imprimer' }).click()
      await etat.page.locator('.modal').waitFor({ state: 'detached' })
      durees.push(performance.now() - depart)
      assert.equal(encaissements(etat).length, avant + 1)
    }
  } finally {
    await etat.context.close()
  }
  return { mediane: percentile(durees, .5), p95: percentile(durees, .95) }
}

test('les catalogues réels tiennent les trois écrans tactiles sans débordement', async () => {
  const cas = [
    ['superette-el-baraka', 187],
    ['mistral-coffee', 112]
  ]
  for (const [carte, attendu] of cas) {
    for (const [width, height] of [[1024, 768], [1366, 768], [1920, 1080]]) {
      const etat = await ouvrirCaisse(infra, { carte, width, height })
      try {
        assert.equal(etat.catalogue.products.length, attendu)
        const bilan = await etat.page.evaluate(() => {
          const racine = document.documentElement
          const cibles = [...document.querySelectorAll('button:not([disabled]), a[href], input')]
            .filter(e => {
              const r = e.getBoundingClientRect()
              return r.width > 0 && r.height > 0
            })
            .map(e => {
              const r = e.getBoundingClientRect()
              return { largeur: r.width, hauteur: r.height, texte: e.getAttribute('aria-label') || e.textContent?.trim() || e.tagName }
            })
          return {
            debordement: racine.scrollWidth - racine.clientWidth,
            plusPetiteCible: Math.min(...cibles.map(c => Math.min(c.largeur, c.hauteur))),
            cible: cibles.sort((a, b) => Math.min(a.largeur, a.hauteur) - Math.min(b.largeur, b.hauteur))[0]
          }
        })
        assert.ok(bilan.debordement <= 1, `${carte} ${width}x${height}: débordement ${bilan.debordement}px`)
        assert.ok(bilan.plusPetiteCible >= 42,
          `${carte} ${width}x${height}: cible trop petite ${JSON.stringify(bilan.cible)}`)
      } finally {
        await etat.context.close()
      }
    }
  }
})

test('ouverture et encaissement gardent une médiane sous une seconde et un p95 sous trois secondes', async () => {
  // Une première compilation Vite ne représente pas le démarrage de la caisse livrée.
  const chauffe = await ouvrirCaisse(infra)
  await chauffe.context.close()

  for (const carte of ['superette-el-baraka', 'mistral-coffee']) {
    const ouverture = await mesurerOuvertures(carte)
    const encaissement = await mesurerEncaissements(carte)
    console.log(`AUDIT_CAISSE ${carte} ouverture_mediane_ms=${Math.round(ouverture.mediane)}`
      + ` ouverture_p95_ms=${Math.round(ouverture.p95)}`
      + ` encaissement_mediane_ms=${Math.round(encaissement.mediane)}`
      + ` encaissement_p95_ms=${Math.round(encaissement.p95)}`)
    assert.ok(ouverture.mediane < 1000, `${carte}: ouverture médiane ${Math.round(ouverture.mediane)} ms`)
    assert.ok(encaissement.mediane < 1000, `${carte}: encaissement médian ${Math.round(encaissement.mediane)} ms`)
    assert.ok(ouverture.p95 < 3000, `${carte}: ouverture p95 ${Math.round(ouverture.p95)} ms`)
    assert.ok(encaissement.p95 < 3000, `${carte}: encaissement p95 ${Math.round(encaissement.p95)} ms`)
  }
})
