/**
 * Panier : remarques de cuisine unité par unité.
 *
 * Ces contrôles portent sur des montants — la scission d'une ligne ne doit jamais
 * changer d'un millime le total de la commande, ni faire disparaître une remise.
 */
import { createPinia, setActivePinia } from 'pinia'
import { useCartStore } from '../src/stores/cart.js'

setActivePinia(createPinia())
const produit = { id: 1, name: 'Cordon Bleu', price: 10 }

let echecs = 0
function check(nom, reel, attendu) {
  const ok = JSON.stringify(reel) === JSON.stringify(attendu)
  if (!ok) echecs++
  console.log((ok ? '  ok   ' : '  ECHEC') + ' ' + nom +
    (ok ? '' : `\n         obtenu  : ${JSON.stringify(reel)}\n         attendu : ${JSON.stringify(attendu)}`))
}
const etat = (c) => c.lines.map(l => ({ q: l.quantity, note: l.note, remise: l.discountAmount }))

const c = useCartStore()

console.log('Répartition des remarques')
c.clear(); c.addLine({ product: produit, quantity: 3 })
c.applyLineNotes(c.lines[0].key, ['Sans oignon', 'Sans oignon', 'Bien cuit'])
check('deux consignes distinctes donnent deux lignes, les identiques regroupées',
  etat(c), [{ q: 2, note: 'Sans oignon', remise: 0 }, { q: 1, note: 'Bien cuit', remise: 0 }])
check('la quantité totale est conservée', c.itemCount, 3)
check('le total est conservé', c.total, 30)

c.clear(); c.addLine({ product: produit, quantity: 3 })
c.applyLineNotes(c.lines[0].key, ['Sans sauce', 'Sans sauce', 'Sans sauce'])
check('une seule consigne ne scinde rien', etat(c), [{ q: 3, note: 'Sans sauce', remise: 0 }])

c.clear(); c.addLine({ product: produit, quantity: 2.5 })
c.applyLineNotes(c.lines[0].key, ['Bien cuit'])
check('une quantité fractionnaire (vente au poids) reste entière',
  etat(c), [{ q: 2.5, note: 'Bien cuit', remise: 0 }])

console.log('Remises')
c.clear(); c.addLine({ product: produit, quantity: 3 })
c.setLineDiscount(c.lines[0].key, 0, 5)
let avant = c.total
c.applyLineNotes(c.lines[0].key, ['A', 'B', 'C'])
check('la remise se répartit sans perte', c.lines.reduce((s, l) => s + l.discountAmount, 0), 5)
check('la scission ne change pas le total', c.total, avant)

c.clear(); c.addLine({ product: produit, quantity: 3 })
c.setLineDiscount(c.lines[0].key, 0, 1)      // 1,000 / 3 ne tombe pas juste
avant = c.total
c.applyLineNotes(c.lines[0].key, ['A', 'B', 'C'])
check('le dernier groupe absorbe l\'arrondi', c.lines.reduce((s, l) => s + l.discountAmount, 0), 1)
check('le total reste exact malgré l\'arrondi', c.total, avant)

// Une ligne remisée qui rejoint une ligne identique non remisée perdrait sa remise
// si la comparaison n'inspectait qu'un seul des deux côtés.
c.clear()
c.addLine({ product: produit, quantity: 1, note: 'Sans oignon' })
const remisee = c.addLine({ product: produit, quantity: 1 })
c.setLineDiscount(remisee.key, 0, 4)
avant = c.total
c.applyLineNotes(remisee.key, ['Sans oignon'])
check('une ligne remisée ne se fond pas dans une ligne sans remise', c.total, avant)

console.log(echecs ? `\n${echecs} échec(s)` : '\nTous les contrôles passent')
process.exit(echecs ? 1 : 0)
