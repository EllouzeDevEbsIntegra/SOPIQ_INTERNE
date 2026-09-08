/**
 * Ce qu'une commande consomme en pâtes, et ce qu'il en reste.
 *
 * Le compteur est posé sur la VALEUR DE VARIANTE, pas sur l'article : la même pâte
 * normale sert quarante sandwichs, et c'est elle qui manque à 21 h. Une valeur peut
 * n'avoir aucun compteur et tirer sur une autre — « Double Normale » consomme deux pâtes
 * normales. C'est donc toujours le compteur du PORTEUR qu'il faut regarder.
 *
 * Ces fonctions ne décident de rien : elles comptent. Le refus, lui, est prononcé une
 * seule fois, dans le panier, pour qu'aucune porte d'entrée ne l'oublie ; et le serveur
 * refuse à son tour, verrou posé sur le compteur, pour deux caisses qui vendraient la
 * même dernière pâte au même instant.
 */

/** Toutes les valeurs de variante du catalogue, par identifiant. */
export function valeursParId(catalog) {
  const m = {}
  for (const axe of catalog.variants || []) for (const v of axe.values || []) m[v.id] = v
  return m
}

/** Le compteur sur lequel une valeur tire, et ce qu'elle y retire à l'unité. */
export function porteurEtPas(valeur) {
  if (!valeur) return null
  if (valeur.stockManaged) return { porteur: valeur.id, pas: Number(valeur.stockStep || 1) }
  if (valeur.stockSourceId) return { porteur: valeur.stockSourceId, pas: Number(valeur.stockStep || 1) }
  return null
}

/**
 * Ce que des lignes de panier retirent, compteur par compteur.
 *
 * Les composants d'un menu comptent aussi : le sandwich d'un menu consomme une pâte
 * comme un autre. Il prend la version par défaut de son article — c'est ce que fait le
 * serveur —, et sa quantité est multipliée par celle du menu : deux menus font deux
 * sandwichs, donc deux pâtes.
 */
export function besoinsDesLignes(lignes, catalog) {
  const valeurs = valeursParId(catalog)
  const besoins = {}
  const ajouter = (valeurId, qte) => {
    const pp = porteurEtPas(valeurs[valeurId])
    if (!pp || !(qte > 0)) return
    besoins[pp.porteur] = (besoins[pp.porteur] || 0) + pp.pas * qte
  }
  for (const l of lignes || []) {
    const q = Number(l.quantity || 0)
    ajouter(l.variantValueId, q)
    for (const c of l.components || []) {
      const p = catalog.productsById?.[c.productId]
      if (p?.defaultVariantValueId) ajouter(p.defaultVariantValueId, Number(c.quantity || 0) * q)
    }
  }
  return besoins
}

/**
 * Le premier manque, dit en une phrase — ou rien du tout.
 *
 * Une phrase, et pas une liste : le caissier est devant un client, il lui faut savoir
 * tout de suite quelle pâte manque et combien il en reste pour proposer autre chose.
 */
export function manque(stock, besoins, catalog) {
  const valeurs = valeursParId(catalog)
  for (const [porteurId, besoin] of Object.entries(besoins)) {
    const reste = stock?.[porteurId]
    if (reste === undefined || reste === null) continue      // pâte non suivie : rien à dire
    if (besoin > Number(reste) + 1e-9) {
      const nom = valeurs[porteurId]?.name || 'cette pâte'
      return `Stock épuisé : il reste ${nombre(reste)} « ${nom} » et il en faudrait ${nombre(besoin)}.`
    }
  }
  return null
}

function nombre(v) {
  const n = Number(v) || 0
  return Number.isInteger(n) ? String(n) : n.toLocaleString('fr-FR', { maximumFractionDigits: 3 })
}
