/**
 * Lire une photo choisie par le gérant, et la ramener à une taille de caisse.
 *
 * POURQUOI REDIMENSIONNER ICI. Les photos ne partent pas sur un serveur de fichiers :
 * elles sont encodées dans la fiche article, parce qu'une caisse installée dans un
 * commerce n'a pas de serveur à côté d'elle et qu'une photo perdue vaut moins qu'une
 * photo lourde. Mais tout ce qui est encodé voyage ensuite dans le catalogue, que CHAQUE
 * caisse recharge à l'ouverture. Une photo de téléphone de 3 Mo par version, sur six
 * versions, rendrait ce chargement insupportable au comptoir.
 *
 * 320 pixels sur le grand côté : les tuiles de vente en font 240 au plus, et un écran à
 * forte densité y trouve encore de quoi rester net.
 */
export function lirePhoto(fichier, { max = 320, qualite = 0.82 } = {}) {
  return new Promise((resolve, reject) => {
    if (!fichier) return resolve(null)
    if (!/^image\//.test(fichier.type)) return reject(new Error("Ce fichier n'est pas une image."))
    const lecteur = new FileReader()
    lecteur.onerror = () => reject(new Error("Image illisible."))
    lecteur.onload = () => {
      const im = new Image()
      im.onerror = () => reject(new Error("Image illisible."))
      im.onload = () => {
        const facteur = Math.min(1, max / Math.max(im.width, im.height))
        // Déjà petite : on garde l'original tel quel plutôt que de le ré-encoder, ce qui
        // ne ferait que perdre de la qualité sans rien gagner en poids.
        if (facteur >= 1) return resolve(lecteur.result)
        const toile = document.createElement('canvas')
        toile.width = Math.round(im.width * facteur)
        toile.height = Math.round(im.height * facteur)
        const ctx = toile.getContext('2d')
        ctx.imageSmoothingQuality = 'high'
        ctx.drawImage(im, 0, 0, toile.width, toile.height)
        // JPEG : une photo de produit n'a pas de transparence, et le PNG y pèserait
        // quatre fois plus pour le même résultat.
        resolve(toile.toDataURL('image/jpeg', qualite))
      }
      im.src = lecteur.result
    }
    lecteur.readAsDataURL(fichier)
  })
}
