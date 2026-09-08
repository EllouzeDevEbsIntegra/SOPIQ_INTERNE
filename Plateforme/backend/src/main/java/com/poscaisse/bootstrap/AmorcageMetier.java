package com.poscaisse.bootstrap;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.poscaisse.config.AppProperties;
import com.poscaisse.dto.CatalogImportDtos.CatalogImport;
import com.poscaisse.dto.CatalogImportDtos.ImportResult;
import com.poscaisse.service.CatalogImportService;
import com.poscaisse.service.SettingsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.Map;

/**
 * Ce qu'un poste neuf devient : un cafe, une superette, un restaurant.
 *
 * LE PROBLEME QUE CELA RESOUT. Vendre un abonnement creait une base vide. Il fallait
 * ensuite ouvrir un terminal, lancer un script PowerShell contre la caisse avec le mot de
 * passe administrateur, et cocher une a une les cases du metier dans le back-office. Trois
 * cents clients, c'est trois cents fois cette manipulation, et une fois sur dix on oublie
 * une case. Le poste se configure maintenant lui-meme, a partir de deux variables.
 *
 * DEUX VARIABLES, ET RIEN D'AUTRE :
 * <pre>
 *   POSCAISSE_PROFIL=CAFE          le metier - il pose les reglages et choisit la carte
 *   POSCAISSE_DEMO_DATA=false      << repartir de zero >> : la maison, une caisse, et rien
 * </pre>
 *
 * QUAND CELA S'EXECUTE, ET SURTOUT QUAND CELA NE S'EXECUTE PAS. Uniquement sur une base
 * ou aucune societe n'est encore enregistree. Un poste en service au comptoir ne doit
 * jamais voir sa carte remplacee ni ses reglages remis a ceux du profil parce qu'une
 * variable d'environnement a change au redemarrage - ce serait effacer le travail du
 * client par accident.
 *
 * LA CARTE EST DANS LE JAR. Elle n'est pas lue sur le disque : un poste installe dans un
 * commerce n'a pas le depot de sources a cote de lui, et une carte manquante au premier
 * demarrage donnerait une caisse vide sans que personne comprenne pourquoi.
 */
@Service @RequiredArgsConstructor @Slf4j
public class AmorcageMetier {

    private final AppProperties props;
    private final SettingsService settings;
    private final CatalogImportService importation;
    private final ObjectMapper om;

    /** Le profil demande, ou {@code null} si le poste n'en declare aucun (installation historique). */
    public ProfilMetier profilConfigure() {
        String nom = props.getMetier().getProfil();
        ProfilMetier p = ProfilMetier.parNom(nom);
        if (p == null && nom != null && !nom.isBlank())
            log.warn("Profil métier « {} » inconnu : la caisse démarre sans profil. Attendu : RESTO, CAFE, SHOP, VETEMENT, PATISSERIE ou PARFUMERIE.", nom);
        return p;
    }

    /** Faut-il poser une carte de demonstration, ou laisser le client saisir la sienne ? */
    public boolean avecDemonstration() { return props.isDemoData(); }

    /**
     * L'enseigne a inscrire sur les tickets : celle du client, sinon celle de la demonstration.
     *
     * LES ACCENTS SE PERDENT EN CHEMIN, ET IL FAUT LE DIRE. Une variable d'environnement
     * est une suite d'octets ; la machine virtuelle la lit avec l'encodage du systeme, et
     * un serveur demarre sans langue configuree lit en ASCII. << SUPERETTE >> accentue
     * arrive alors ampute de son E - deux caracteres de remplacement a la place - et ce
     * nom abime s'imprimerait sur chaque ticket du commerce.
     *
     * On ne l'enregistre pas. Le profil donne son enseigne en attendant, le journal dit
     * exactement quoi corriger (LANG=C.UTF-8 au lancement), et le gerant peut de toute
     * facon poser la sienne depuis l'ecran Societe - saisie au clavier, elle, arrive
     * intacte.
     */
    public String enseigne(ProfilMetier profil) {
        String choisie = props.getMetier().getEnseigne();
        if (choisie == null || choisie.isBlank()) return profil.enseigne();
        choisie = choisie.trim();
        if (choisie.indexOf('\uFFFD') >= 0) {
            log.error("L'enseigne « {} » est arrivée abîmée : ses accents ont été perdus avant d'atteindre "
                    + "la caisse, parce que la machine lit son environnement en « {} » et non en UTF-8. "
                    + "Relancez avec LANG=C.UTF-8. En attendant, l'enseigne du profil est posée ; "
                    + "corrigez-la dans le back-office, écran Société.",
                    choisie, System.getProperty("sun.jnu.encoding"));
            return profil.enseigne();
        }
        return choisie;
    }

    /**
     * Poser les reglages du metier.
     *
     * Ils sont ECRITS en base, pas seulement laisses par defaut : le gerant doit les voir
     * dans son back-office, coches, et pouvoir les changer. Un reglage invisible n'est pas
     * un reglage, c'est une decision prise a sa place.
     */
    public void poserLesReglages(ProfilMetier profil) {
        Map<String, String> r = profil.reglages();
        settings.update(r);
        log.info("Profil {} : {} réglages posés ({}).", profil.name(), r.size(),
                r.entrySet().stream().map(e -> e.getKey() + '=' + e.getValue()).reduce((a, b) -> a + ", " + b).orElse(""));
    }

    /**
     * Charger la carte de demonstration du profil.
     *
     * Une carte absente n'arrete pas le demarrage : mieux vaut une caisse vide qui ouvre
     * qu'un poste qui refuse de se lancer le matin devant un comptoir plein.
     */
    public void chargerLaCarte(ProfilMetier profil) {
        if (profil.carte() == null) return;
        String chemin = "cartes/" + profil.carte();
        try (InputStream flux = new ClassPathResource(chemin).getInputStream()) {
            CatalogImport carte = om.readValue(flux, CatalogImport.class);
            ImportResult r = importation.importCatalog(carte, true);
            log.info("Carte de démonstration « {} » chargée : {} articles, {} catégories, {} variantes.",
                    r.label(), r.productsCreated(), r.categoriesCreated(), r.variantsCreated());
        } catch (Exception e) {
            log.error("Carte de démonstration « {} » non chargée : {}. La caisse démarre avec un catalogue vide.",
                    chemin, e.getMessage());
        }
    }
}
