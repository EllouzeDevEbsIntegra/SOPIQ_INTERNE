package com.poscaisse.bootstrap;

import com.poscaisse.service.SettingsService;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Les metiers que la caisse sait tenir, et ce qui les distingue.
 *
 * OUVRIR UNE VERTICALE, C'EST REMPLIR UNE LIGNE ICI. Le code de vente ne connait aucun
 * metier : il lit des reglages. Un profil n'est donc rien d'autre qu'un jeu de valeurs de
 * depart et le nom d'une carte de demonstration. Rien de ce qui suit n'est verrouille - le
 * client change chaque reglage depuis son back-office le jour ou son commerce change.
 *
 * CE QUI EST VRAI DU MARCHE, ET CE QUI EST UN CHOIX. Les modes de service, le scan et la
 * facon de compter viennent du metier reel : une superette scanne et compte tout, un cafe
 * ne scanne rien et ne compte que ses bouteilles. Les montants d'especes rapides et la
 * taille des tuiles sont un confort : ils suivent le panier moyen du metier - on rend
 * rarement la monnaie sur 50 dinars dans un cafe, et un ecran de 187 references se lit
 * mieux en petites tuiles.
 *
 * LA RUPTURE DE STOCK. Le restaurant REFUSE : il ne peut pas servir ce qu'il n'a pas. Le
 * commerce AVERTIT : le rayon a souvent raison contre le compteur, et bloquer une vente
 * devant le client pour un ecart d'inventaire coute plus cher que l'ecart.
 */
public enum ProfilMetier {

    /**
     * Restaurant, fast-food. Pas de scan, le stock se tient sur la pate et non sur
     * l'article, et la vente se refuse quand il n'y a plus.
     *
     * Sa carte de demonstration est celle qui est ecrite dans le code (FAST FOOD DEMO) et
     * non un fichier : elle contient des MENUS composes, que le format d'import ne sait
     * pas encore porter. Le jour ou il les portera, cette ligne recevra un fichier comme
     * les autres.
     */
    RESTO("Restaurant / Fast-food", "FAST FOOD DÉMO", null, reglages(
            "DINE_IN,TAKEAWAY,DELIVERY", "DINE_IN", false, "aucun", "refuser", "libre", "5,10,20,50", "M")),

    /** Cafe, salon de the. Consommation sur place, chicha, cartes ; petits montants. */
    CAFE("Café / Salon de thé", "MISTRAL COFFEE", "mistral-coffee.json", reglages(
            "DINE_IN,TAKEAWAY", "DINE_IN", false, "partiel", "avertir", "libre", "1,2,5,10", "M")),

    /** Superette, epicerie. Tout se scanne, tout se compte, tout entre par un achat. */
    SHOP("Supérette / Épicerie", "SUPÉRETTE EL BARAKA", "superette-el-baraka.json", reglages(
            "TAKEAWAY", "TAKEAWAY", true, "total", "avertir", "achat", "5,10,20,50", "S")),

    /** Pret-a-porter. Le scan de l'etiquette, le stock par taille, des paniers plus gros. */
    VETEMENT("Prêt-à-porter", "STYLE BOUTIQUE", "style-boutique.json", reglages(
            "TAKEAWAY", "TAKEAWAY", true, "total", "avertir", "achat", "20,50,100,200", "M")),

    /** Patisserie. Emporte le plus souvent, un peu de salon ; pas de scan sur un gateau. */
    PATISSERIE("Pâtisserie", "DAR HALWA", "dar-halwa.json", reglages(
            "DINE_IN,TAKEAWAY", "TAKEAWAY", false, "partiel", "avertir", "libre", "1,2,5,10,20", "M")),

    /**
     * Parfumerie. Le scan est ACTIVE : les coffrets portent un code-barres du fabricant,
     * et c'est ainsi qu'on les vend. C'est le seul profil que le cahier des charges ne
     * tranchait pas ; une case a decocher si le commerce ne scanne pas.
     */
    PARFUMERIE("Parfumerie", "NOUR PARFUMS", "nour-parfums.json", reglages(
            "TAKEAWAY", "TAKEAWAY", true, "total", "avertir", "achat", "20,50,100,200", "M"));

    private final String libelle;
    private final String enseigne;
    private final String carte;
    private final Map<String, String> reglages;

    ProfilMetier(String libelle, String enseigne, String carte, Map<String, String> reglages) {
        this.libelle = libelle; this.enseigne = enseigne; this.carte = carte; this.reglages = reglages;
    }

    public String libelle() { return libelle; }
    /** L'enseigne de la base de demonstration - jamais celle d'un vrai client. */
    public String enseigne() { return enseigne; }
    /** Le fichier de carte dans {@code classpath:cartes/}, ou {@code null} pour le RESTO. */
    public String carte() { return carte; }
    /** Ce que le profil pose au premier demarrage, et que le client peut ensuite changer. */
    public Map<String, String> reglages() { return reglages; }

    /** Le profil nomme, quelle que soit la casse ; {@code null} si le nom ne dit rien. */
    public static ProfilMetier parNom(String nom) {
        if (nom == null || nom.isBlank()) return null;
        for (ProfilMetier p : values()) if (p.name().equalsIgnoreCase(nom.trim())) return p;
        return null;
    }

    private static Map<String, String> reglages(String modes, String modeParDefaut, boolean codeBarres,
                                                String stockMode, String rupture, String entree,
                                                String especesRapides, String tailleTuile) {
        Map<String, String> m = new LinkedHashMap<>();
        m.put(SettingsService.SERVICE_MODES, modes);
        m.put(SettingsService.DEFAULT_SERVICE_MODE, modeParDefaut);
        m.put(SettingsService.BARCODE_ENABLED, Boolean.toString(codeBarres));
        m.put(SettingsService.STOCK_MODE, stockMode);
        m.put(SettingsService.STOCK_RUPTURE, rupture);
        m.put(SettingsService.STOCK_ENTREE, entree);
        m.put(SettingsService.QUICK_CASH, especesRapides);
        m.put(SettingsService.TILE_SIZE, tailleTuile);
        return m;
    }
}
