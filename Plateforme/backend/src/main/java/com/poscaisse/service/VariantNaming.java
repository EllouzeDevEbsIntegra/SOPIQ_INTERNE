package com.poscaisse.service;

import com.poscaisse.domain.Enums;
import com.poscaisse.domain.OrderLine;
import com.poscaisse.domain.Product;
import com.poscaisse.domain.VariantValue;

/**
 * Compose le nom d'un article avec sa variante.
 *
 * Écrit une fois et appelé partout — ticket client, ticket de cuisine, panier, relevés :
 * si chaque écran composait le nom à sa façon, le client lirait « Pizza Thon Large » sur
 * son ticket et la cuisine « Large Pizza Thon » sur le sien.
 *
 * La position vient de l'axe, pas d'une règle générale, parce que le français ne place pas
 * toutes les déclinaisons du même côté : on dit « Pizza Thon Large » mais « 1/2 Sandwich
 * Omelette Thon ».
 */
public final class VariantNaming {
    private VariantNaming() {}

    /** Nom à imprimer pour une ligne déjà vendue : on lit la COPIE, jamais le catalogue. */
    public static String forLine(OrderLine l) {
        return compose(l.getProductName(), l.getVariantValueShortName(), l.getVariantValueName(), position(l));
    }

    /** Nom à afficher pour une vente en cours, avant enregistrement. */
    public static String forSale(Product p, VariantValue v) {
        if (v == null) return p.getName();
        Enums.NamePosition pos = v.getVariant() == null ? Enums.NamePosition.SUFFIX : v.getVariant().getNamePosition();
        return compose(p.getName(), v.getShortName(), v.getName(), pos);
    }

    /**
     * La position d'une ligne vendue se relit sur l'axe, qui peut avoir change depuis.
     * C'est le seul emprunt au catalogue : deplacer « 1/2 » du prefixe au suffixe change
     * la mise en forme d'un vieux ticket reimprime, jamais ce qui a ete vendu ni son prix.
     */
    private static Enums.NamePosition position(OrderLine l) {
        VariantValue v = l.getVariantValue();
        if (v == null || v.getVariant() == null) return Enums.NamePosition.SUFFIX;
        return v.getVariant().getNamePosition();
    }

    private static String compose(String base, String court, String complet, Enums.NamePosition pos) {
        String mot = court == null || court.isBlank() ? complet : court;
        if (mot == null || mot.isBlank()) return base;
        return pos == Enums.NamePosition.PREFIX ? mot + " " + base : base + " " + mot;
    }
}
