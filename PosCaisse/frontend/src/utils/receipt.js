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
 *
 * Une troisième paire encadre un passage DANS une ligne, et non la ligne entière :
 *
 *   U+000E / U+000F  emphase ouverte puis refermée — la variante vendue, « Céréale »,
 *           au milieu du nom de l'article. Ces marqueurs ne prennent pas de place sur
 *           le papier : le serveur a calibré ses colonnes sans les compter.
 */
const BIG = 0x01
const HEAD = 0x02
const EMPH_ON = '\u000E'
const EMPH_OFF = '\u000F'

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
  return sansEmphase(line).trim().split(/\s{2,}/).filter(Boolean)
}

/** Le texte sans ses marqueurs d'emphase, pour un support qui ne sait pas les rendre. */
export function sansEmphase(text) {
  return String(text ?? '').replace(/[\u000E\u000F]/g, '')
}

/**
 * Découpe un texte en segments { text, emph } : ce qui est encadré par les marqueurs
 * d'emphase d'un côté, le reste de l'autre. Les marqueurs eux-mêmes disparaissent.
 */
export function emphSegments(text) {
  const out = []
  let emph = false
  let buf = ''
  for (const ch of String(text ?? '')) {
    if (ch !== EMPH_ON && ch !== EMPH_OFF) { buf += ch; continue }
    if (buf) out.push({ text: buf, emph })
    buf = ''
    emph = ch === EMPH_ON
  }
  if (buf || !out.length) out.push({ text: buf, emph })
  return out
}

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')

/** Le même ticket en HTML, pour la fenêtre d'impression. `logo` est une balise img déjà prête. */
export function receiptHtml(content, logo = '') {
  return receiptBlocks(content).map(b => {
    if (b.kind !== 'head') {
      const txt = emphSegments(b.lines.join('\n'))
        .map(s => (s.emph ? `<b>${esc(s.text)}</b>` : esc(s.text))).join('')
      return `<pre${b.kind === 'big' ? ' class="big"' : ''}>${txt}</pre>`
    }
    const rows = b.lines.map((l, i) => {
      const parts = headFields(l)
      if (!parts.length) return ''
      const cls = i === 0 ? 'name' : 'when'
      return `<div class="${cls}${parts.length > 1 ? ' split' : ''}">${parts.map(p => `<span>${esc(p)}</span>`).join('')}</div>`
    }).join('')
    return `<div class="head">${logo}<div class="head-txt">${rows}</div></div>`
  }).join('')
}

/**
 * Nom d'une ligne, variante comprise.
 *
 * Jumeau de VariantNaming cote serveur. Les deux doivent donner la meme chaine : le
 * caissier lirait « Pizza Thon Large » a l'ecran et le client « Large Pizza Thon » sur son
 * ticket. La position vient de l'axe, parce que le francais ne place pas toutes les
 * declinaisons du meme cote : « Pizza Thon Large », mais « 1/2 Sandwich Omelette Thon ».
 */
export function nomAvecVariante(ligne, variantes) {
  const base = ligne.product?.name || ligne.productName || ''
  if (!ligne.variantValueId) return base
  const axe = (variantes || []).find(v => (v.values || []).some(x => x.id === ligne.variantValueId))
  const val = axe?.values.find(x => x.id === ligne.variantValueId)
  const mot = val?.shortName || val?.name || ligne.variantValueName
  if (!mot) return base
  return axe?.namePosition === 'PREFIX' ? mot + ' ' + base : base + ' ' + mot
}
