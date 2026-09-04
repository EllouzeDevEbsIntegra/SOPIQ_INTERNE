/**
 * Mise en forme des tickets rendus par le serveur.
 *
 * Le serveur produit du texte monospace, imprimable tel quel. Deux familles de lignes
 * portent un marqueur en tête, que l'imprimante traduit dans sa propre mise en forme —
 * le navigateur aujourd'hui, un pilote ESC/POS demain :
 *
 *   U+0001  ligne mise en avant (double hauteur, gras). Son texte est déjà centré sur
 *           la moitié des colonnes, puisqu'il s'affiche deux fois plus large.
 *   U+0002  ligne d'en-tête. Le bloc se dispose à droite du logo : l'enseigne au-dessus,
 *           la date et l'heure en dessous, séparées par l'espace qui les tient aux deux
 *           bords. Ces lignes restent remplies pour la largeur du papier, donc lisibles
 *           telles quelles sur un support qui ignore le marqueur.
 */
const BIG = 0x01
const HEAD = 0x02

/** Découpe le ticket en blocs homogènes : { kind: 'text' | 'big' | 'head', lines }. */
export function receiptBlocks(content) {
  const out = []
  for (const raw of String(content ?? '').split('\n')) {
    const c = raw.charCodeAt(0)
    const kind = c === BIG ? 'big' : c === HEAD ? 'head' : 'text'
    const text = kind === 'text' ? raw : raw.slice(1)
    const last = out[out.length - 1]
    if (last && last.kind === kind) last.lines.push(text)
    else out.push({ kind, lines: [text] })
  }
  return out
}

/**
 * Les champs d'une ligne d'en-tête. Le serveur les a séparés par le remplissage qui les
 * tient aux deux bords du papier : deux espaces ou plus marquent donc la coupure.
 */
export function headFields(line) {
  return line.trim().split(/\s{2,}/).filter(Boolean)
}

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')

/** Le même ticket en HTML, pour la fenêtre d'impression. `logo` est une balise img déjà prête. */
export function receiptHtml(content, logo = '') {
  return receiptBlocks(content).map(b => {
    if (b.kind !== 'head') return `<pre${b.kind === 'big' ? ' class="big"' : ''}>${esc(b.lines.join('\n'))}</pre>`
    const rows = b.lines.map((l, i) => {
      const parts = headFields(l)
      if (!parts.length) return ''
      const cls = i === 0 ? 'name' : 'when'
      return `<div class="${cls}${parts.length > 1 ? ' split' : ''}">${parts.map(p => `<span>${esc(p)}</span>`).join('')}</div>`
    }).join('')
    return `<div class="head">${logo}<div class="head-txt">${rows}</div></div>`
  }).join('')
}
