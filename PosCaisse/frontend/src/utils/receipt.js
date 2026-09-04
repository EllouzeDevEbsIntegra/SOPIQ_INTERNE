/**
 * Mise en forme des tickets rendus par le serveur.
 *
 * Le serveur produit du texte monospace, imprimable tel quel. Les lignes à mettre en
 * avant — nom du restaurant, numéro de ticket — portent un marqueur en tête (U+0001) ;
 * à l'impression elles passent en double hauteur et en gras, ce qu'une imprimante
 * ESC/POS fera un jour avec ses propres codes. Le texte de ces lignes est déjà centré
 * sur la moitié des colonnes, puisqu'il s'affiche deux fois plus large.
 */
const MARK = 0x01

/** Découpe le ticket en blocs homogènes : { big, text }. */
export function receiptBlocks(content) {
  const out = []
  for (const raw of String(content ?? '').split('\n')) {
    const big = raw.charCodeAt(0) === MARK
    const text = big ? raw.slice(1) : raw
    const last = out[out.length - 1]
    if (last && last.big === big) last.text += '\n' + text
    else out.push({ big, text })
  }
  return out
}

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')

/** Le même ticket en HTML, pour la fenêtre d'impression. */
export function receiptHtml(content) {
  return receiptBlocks(content)
    .map(b => `<pre${b.big ? ' class="big"' : ''}>${esc(b.text)}</pre>`)
    .join('')
}
