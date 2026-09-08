package com.poscaisse.dto;

import java.util.List;

/** Résultat du nettoyage définitif du catalogue. */
public final class CatalogPurgeDtos {
    private CatalogPurgeDtos() {}

    /**
     * @param salesReset        vrai si les données transactionnelles ont été effacées
     * @param salesRowsDeleted  nombre total de lignes supprimées dans les tables de vente
     * @param productsDeleted   produits inactifs réellement supprimés
     * @param categoriesDeleted catégories supprimées (plus aucun produit ni ligne de vente)
     * @param groupsDeleted     groupes d'options devenus orphelins
     * @param productsLeft      produits restants après nettoyage
     * @param categoriesLeft    catégories restantes après nettoyage
     * @param warnings          ce qui n'a pas pu être supprimé, et pourquoi
     */
    public record PurgeResult(boolean salesReset, int salesRowsDeleted, int productsDeleted,
                              int categoriesDeleted, int groupsDeleted, int productsLeft,
                              int categoriesLeft, List<String> warnings) {}
}
