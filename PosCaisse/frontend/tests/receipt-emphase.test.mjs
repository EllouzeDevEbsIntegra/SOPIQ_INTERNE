/**
 * Ticket : la variante vendue s'imprime en gras au milieu du nom.
 *
 * Le serveur l'encadre de deux marqueurs (U+000E / U+000F) qui ne prennent pas de place
 * sur le papier. Le navigateur doit les traduire en <b> — et surtout ne jamais les
 * laisser passer tels quels, où ils se liraient comme des caractères parasites.
 */
import { emphSegments, headFields, receiptBlocks, receiptHtml, sansEmphase } from '../src/utils/receipt.js'

const ON = ''
const OFF = ''
const BIG = ''

let echecs = 0
function check(nom, reel, attendu) {
  const ok = JSON.stringify(reel) === JSON.stringify(attendu)
  if (!ok) echecs++
  console.log((ok ? '  ok   ' : '  ECHEC') + ' ' + nom +
    (ok ? '' : `\n         obtenu  : ${JSON.stringify(reel)}\n         attendu : ${JSON.stringify(attendu)}`))
}

console.log('Découpe en segments')
check('un nom avec variante donne trois segments',
  emphSegments(`1 x Oml Moz Thon ${ON}Cér${OFF}   10,500`),
  [{ text: '1 x Oml Moz Thon ', emph: false }, { text: 'Cér', emph: true }, { text: '   10,500', emph: false }])
check('une variante en préfixe ouvre la ligne',
  emphSegments(`${ON}1/2${OFF} Sandwich Thon`),
  [{ text: '1/2', emph: true }, { text: ' Sandwich Thon', emph: false }])
check('une ligne sans marqueur reste un seul segment',
  emphSegments('TOTAL                    17,000'),
  [{ text: 'TOTAL                    17,000', emph: false }])
check('une ligne vide donne un segment vide', emphSegments(''), [{ text: '', emph: false }])
check('le texte nu perd ses marqueurs', sansEmphase(`Oml ${ON}Cér${OFF}`), 'Oml Cér')

console.log('\nRendu HTML')
const html = receiptHtml(`1 x Oml Moz Thon ${ON}Cér${OFF}   10,500`)
check('le passage encadré devient une balise gras',
  html, '<pre>1 x Oml Moz Thon <b>Cér</b>   10,500</pre>')
check('aucun marqueur ne survit dans le HTML', new RegExp(`[${ON}${OFF}]`).test(html), false)
check('le HTML reste échappé', receiptHtml(`${ON}<b>${OFF} & co`), '<pre><b>&lt;b></b> &amp; co</pre>')

// La ligne mise en avant (U+0001) et l'en-tête (U+0002) continuent de se lire comme avant.
check('la ligne mise en avant garde sa classe',
  receiptHtml(`${BIG}  N° PV01-2026-000001`), '<pre class="big">  N° PV01-2026-000001</pre>')
check('un en-tête emphasé ne montre pas ses marqueurs',
  headFields(` ${ON}FAST FOOD${OFF}  01/01/2026`), ['FAST FOOD', '01/01/2026'])

console.log('\nDécoupe en blocs')
check("un marqueur d'emphase en tête de ligne n'est pas pris pour un marqueur de ligne",
  receiptBlocks(`${ON}Cér${OFF} Baguette`), [{ kind: 'text', lines: [`${ON}Cér${OFF} Baguette`] }])

console.log(echecs ? `\n${echecs} échec(s)` : '\nTous les contrôles passent')
process.exit(echecs ? 1 : 0)
