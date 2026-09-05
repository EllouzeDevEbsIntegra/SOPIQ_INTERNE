/**
 * Sur un ecran tactile, un champ numerique deja rempli est penible a corriger.
 *
 * Le champ affiche « 0 » ; on le touche, le curseur se pose la ou le doigt est tombe -
 * souvent a gauche du zero - et taper 6 donne « 60 » au lieu de « 6 ». Il faudrait viser
 * la droite du zero puis l'effacer, sur une cible de deux millimetres, sans souris.
 *
 * On selectionne donc tout le contenu des champs numeriques des qu'ils prennent le
 * focus : la premiere touche remplace la valeur, ce que tout le monde attend d'un champ
 * de montant ou de quantite.
 *
 * Limite au numerique a dessein. Sur un champ de texte - un nom d'article, un
 * commentaire de ticket - selectionner tout ferait perdre la saisie au premier caractere
 * de quelqu'un qui voulait seulement corriger une lettre.
 */
const NUMERIQUE = 'input[type="number"], input[inputmode="decimal"], input[inputmode="numeric"]'

export function activerSaisieTactile(racine = document) {
  racine.addEventListener('focusin', (e) => {
    const el = e.target
    if (!el.matches?.(NUMERIQUE) || el.disabled || el.readOnly) return
    // Le focus precede le relachement du doigt, qui reposerait le curseur : on selectionne
    // apres, et on neutralise ce seul relachement-la.
    requestAnimationFrame(() => { try { el.select() } catch { /* type non selectionnable */ } })
    el.addEventListener('mouseup', ev => ev.preventDefault(), { once: true })
  })
}
