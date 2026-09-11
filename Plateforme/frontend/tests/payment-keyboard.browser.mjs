import { after, before, test } from 'node:test'
import assert from 'node:assert/strict'
import { demarrerInterface, ouvrirCaisse, ouvrirPaiement, encaissements } from './interface-fixture.mjs'

let infra
before(async () => { infra = await demarrerInterface() })
after(async () => { await infra?.fermer() })

test('Entrée dans le choix du client ne doit jamais encaisser la vente sous-jacente', async t => {
  const etat = await ouvrirCaisse(infra); t.after(() => etat.context.close())
  await ouvrirPaiement(etat)
  await etat.page.locator('.modal .customer').click()
  const recherche = etat.page.getByPlaceholder('Rechercher un client…')
  await recherche.fill('Client'); await recherche.press('Enter')
  await etat.page.waitForTimeout(150)
  assert.equal(encaissements(etat).length, 0, 'La sélection du client ne doit pas provoquer POST /pos/checkout')
  assert.equal(await etat.page.locator('.modal').count(), 2)
})

test('la fenêtre supérieure porte le focus et Échap revient au paiement', async t => {
  const etat = await ouvrirCaisse(infra); t.after(() => etat.context.close())
  await ouvrirPaiement(etat)
  const choix = etat.page.locator('.modal .customer')
  await choix.click()
  const dialogue = etat.page.getByRole('dialog', { name: 'Choisir le client' })
  await dialogue.waitFor()
  assert.equal(await etat.page.evaluate(() => document.activeElement?.getAttribute('placeholder')), 'Rechercher un client…')
  await etat.page.keyboard.press('Escape')
  assert.equal(await etat.page.locator('.modal').count(), 1)
  assert.equal(await choix.evaluate(e => e === document.activeElement), true)
  assert.equal(encaissements(etat).length, 0)
})

test('Entrée active une tuile article comme un geste tactile', async t => {
  const etat = await ouvrirCaisse(infra); t.after(() => etat.context.close())
  const tuile = etat.page.locator('.tile').first()
  await tuile.focus(); await tuile.press('Enter')
  assert.equal(await etat.page.locator('.cart .line').count(), 1)
})

test('Entrée sur Annuler ferme le paiement sans enregistrer une vente', async t => {
  const etat = await ouvrirCaisse(infra); t.after(() => etat.context.close())
  await ouvrirPaiement(etat)
  await etat.page.getByRole('button', { name: 'Annuler', exact: true }).press('Enter')
  await etat.page.waitForTimeout(150)
  assert.equal(encaissements(etat).length, 0, 'Annuler au clavier ne doit pas encaisser')
  assert.equal(await etat.page.locator('.modal').count(), 0)
})

test('Entrée dans le pavé ajoute un paiement partiel sans solder le ticket', async t => {
  const etat = await ouvrirCaisse(infra); t.after(() => etat.context.close())
  await ouvrirPaiement(etat)
  await etat.page.locator('.modal .numpad').locator('..').press('1')
  await etat.page.locator('.modal .numpad').locator('..').press('Enter')
  await etat.page.waitForTimeout(150)
  assert.equal(encaissements(etat).length, 0, 'Paiement partiel ne doit pas confirmer la vente')
  assert.equal(await etat.page.locator('.ledger li').count(), 1)
})

test('Entrée sur Valider et imprimer enregistre exactement une vente', async t => {
  const etat = await ouvrirCaisse(infra); t.after(() => etat.context.close())
  await ouvrirPaiement(etat)
  await etat.page.getByRole('button', { name: 'Valider et imprimer' }).press('Enter')
  await etat.page.waitForTimeout(150)
  assert.equal(encaissements(etat).length, 1)
  assert.deepEqual(etat.erreurs, [])
})
