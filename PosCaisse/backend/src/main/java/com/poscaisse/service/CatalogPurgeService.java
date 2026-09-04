package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.Enums;
import com.poscaisse.dto.CatalogPurgeDtos.PurgeResult;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.SessionRepo;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/**
 * Nettoyage définitif du catalogue.
 *
 * L'import en mode « remplacer » ne peut que désactiver un produit déjà vendu :
 * ses lignes de vente le référencent et l'historique doit rester cohérent.
 * Ce service assume la suppression, et ne la propose que de façon explicite :
 *
 * <ul>
 *   <li>{@code resetSales = false} : ne supprime que les produits inactifs
 *       qui n'ont aucune ligne de vente, et les catégories devenues vides.
 *       Sans effet de bord sur l'historique.</li>
 *   <li>{@code resetSales = true} : efface d'abord <b>toutes</b> les données
 *       transactionnelles (tickets, lignes, paiements, remboursements,
 *       mouvements, journal, sessions, clôtures, numérotation), ce qui libère
 *       les produits inactifs, puis supprime le catalogue inactif.
 *       C'est la remise à zéro d'avant mise en production.</li>
 * </ul>
 *
 * Les suppressions sont écrites en SQL natif : les cascades sont déclarées dans
 * le schéma (V1), et un {@code DELETE} JPA entité par entité sur des milliers de
 * lignes n'apporterait rien ici.
 */
@Service @RequiredArgsConstructor @Slf4j
public class CatalogPurgeService {

    private final EntityManager em;
    private final SessionRepo sessionRepo;
    private final AuditService audit;

    /** Ordre imposé par les clés étrangères sans ON DELETE CASCADE (refund → sale_order). */
    private static final List<String> SALES_TABLES = List.of(
            "print_job", "refund", "payment", "order_line_modifier", "order_line",
            "sale_order", "cash_movement", "register_journal", "daily_closure",
            "register_session", "document_sequence");

    @Transactional
    public PurgeResult purge(boolean resetSales) {
        List<String> warnings = new ArrayList<>();

        // Une session ouverte serait supprimée sous les pieds du caissier : on refuse.
        if (resetSales && !sessionRepo.findByStatusOrderByOpenedAtDesc(Enums.SessionStatus.OPEN).isEmpty())
            throw new BusinessException("Une caisse est encore ouverte. Fermez-la avant la remise à zéro des ventes.");

        int salesDeleted = 0;
        if (resetSales) {
            for (String table : SALES_TABLES) salesDeleted += exec("DELETE FROM " + table);
            log.warn("Remise à zéro des ventes : {} lignes supprimées.", salesDeleted);
        }

        // ---- produits inactifs ----
        // Ceux encore référencés par une ligne de vente sont laissés en place :
        // les supprimer casserait un ticket déjà imprimé.
        int blocked = count("""
                SELECT count(*) FROM product p WHERE p.active = false
                  AND EXISTS (SELECT 1 FROM order_line ol WHERE ol.product_id = p.id)""");
        if (blocked > 0) warnings.add(blocked + " produit(s) inactif(s) conservé(s) : encore présents sur des tickets. "
                + "Relancez avec la remise à zéro des ventes pour les supprimer.");

        // menu_component_product et product_modifier_group disparaissent par cascade
        // (déclarée dans V1) ; menu_component aussi via menu_product_id.
        int productsDeleted = exec("""
                DELETE FROM product p WHERE p.active = false
                  AND NOT EXISTS (SELECT 1 FROM order_line ol WHERE ol.product_id = p.id)
                  AND NOT EXISTS (SELECT 1 FROM menu_component_product mcp WHERE mcp.product_id = p.id
                                    AND EXISTS (SELECT 1 FROM menu_component mc
                                                 JOIN product mp ON mp.id = mc.menu_product_id
                                                WHERE mc.id = mcp.menu_component_id AND mp.active = true))""");

        // ---- catégories inactives ou vidées ----
        int categoriesDeleted = exec("""
                DELETE FROM category c
                 WHERE NOT EXISTS (SELECT 1 FROM product p WHERE p.category_id = c.id)
                   AND NOT EXISTS (SELECT 1 FROM order_line ol WHERE ol.category_id = c.id)""");

        // ---- groupes d'options devenus orphelins ----
        // modifier disparaît par cascade ; on épargne ceux encore cités par un ticket.
        int groupsDeleted = exec("""
                DELETE FROM modifier_group g
                 WHERE NOT EXISTS (SELECT 1 FROM product_modifier_group pmg WHERE pmg.modifier_group_id = g.id)
                   AND NOT EXISTS (SELECT 1 FROM order_line_modifier olm
                                     JOIN modifier m ON m.id = olm.modifier_id
                                    WHERE m.group_id = g.id)""");

        int productsLeft = count("SELECT count(*) FROM product");
        int categoriesLeft = count("SELECT count(*) FROM category");

        audit.log("CATALOG_PURGE", "Catalog", null, String.format(
                "resetSales=%s, ventes=%d, produits=%d, categories=%d, groupes=%d",
                resetSales, salesDeleted, productsDeleted, categoriesDeleted, groupsDeleted));

        return new PurgeResult(resetSales, salesDeleted, productsDeleted, categoriesDeleted, groupsDeleted,
                productsLeft, categoriesLeft, warnings);
    }

    private int exec(String sql) { return em.createNativeQuery(sql).executeUpdate(); }

    private int count(String sql) {
        return ((Number) em.createNativeQuery(sql).getSingleResult()).intValue();
    }
}
