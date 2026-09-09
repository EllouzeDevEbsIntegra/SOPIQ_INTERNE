package com.poscaisse.plateforme.service;

import com.poscaisse.plateforme.domain.*;
import com.poscaisse.plateforme.repository.AbonnementRepo;
import com.poscaisse.plateforme.security.UtilisateurCourant;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.OffsetDateTime;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Creer la base d'un client, et son compte pour y acceder.
 *
 * CE QUE FAIT CETTE ETAPE, ET CE QU'ELLE NE FAIT PAS. Elle prepare le contenant : une base
 * vide, un utilisateur PostgreSQL qui n'a de droits QUE sur elle, et un mot de passe tire
 * au sort. Elle ne pose ni les tables ni la carte de demonstration : c'est l'application de
 * caisse qui migre son schema au demarrage, et elle seule sait le faire - dupliquer ses
 * migrations ici les ferait diverger au premier correctif.
 *
 * POURQUOI UN UTILISATEUR PAR BASE. C'est la derniere barriere quand tout le reste a
 * echoue. Un compte unique qui verrait les trois cents bases transformerait n'importe
 * quelle faille d'injection en fuite generale ; ici, le compte du client A ne peut meme
 * pas ouvrir la base du client B.
 *
 * LE MOT DE PASSE NE SE RELIT PAS. Il est rendu UNE FOIS, a la creation, et n'est stocke
 * nulle part - ni en base, ni dans un journal. Perdu, il se change ; garde quelque part,
 * il se vole.
 */
@Service @RequiredArgsConstructor
public class ProvisionnementService {
    private static final Logger log = LoggerFactory.getLogger(ProvisionnementService.class);
    private static final SecureRandom ALEA = new SecureRandom();

    private final AbonnementRepo abonnements;
    private final JournalService journal;
    private final UtilisateurCourant courant;
    /*
        Les gestes PostgreSQL vivent dans UN seul endroit. Ils etaient ecrits deux fois -
        ici et pour les demonstrations - avec deux commentaires identiques ; ils ont
        commence a diverger au premier correctif, celui du << must be able to SET ROLE >>
        que seul un serveur en moindre privilege revelait.
    */
    private final BasesPostgres bases;

    @Value("${plateforme.provisionnement.hote:localhost}") private String hote;
    @Value("${plateforme.provisionnement.port:5432}") private String port;
    /** Modele du nom de base : le code client, en minuscules, sans tiret. */
    @Value("${plateforme.provisionnement.prefixe:pos_}") private String prefixe;

    /**
     * Prepare la base d'un abonnement, et rend de quoi lancer sa caisse.
     *
     * Idempotent sur l'essentiel : si la base existe deja, on ne la recree pas et on ne
     * touche a rien - relancer par erreur ne doit pas effacer un client en service.
     */
    @Transactional
    public Map<String, String> provisionner(Long abonnementId, Boolean demonstration) {
        courant.exige(Enums.Droit.GERER_CLIENTS);
        Abonnement a = abonnements.findById(abonnementId).orElseThrow(() -> ErreurMetier.introuvable("Abonnement"));
        Client c = a.getClient();

        // Le choix de la vente, s'il est refait ici, remplace celui d'avant : c'est le
        // dernier avis du commercial qui compte, et il reste ecrit.
        if (demonstration != null) a.setAvecDemonstration(demonstration);

        String base = a.getBaseNom() != null ? a.getBaseNom() : nomDeBase(c, a);
        String utilisateur = base;
        String motDePasse = motDePasse();

        if (bases.existe(base)) {
            /*
                Deja la. On ne recree pas, on ne remet pas de mot de passe : un
                provisionnement relance par megarde sur un client en service ne doit rien
                casser. Celui qui veut vraiment un nouveau mot de passe le demande
                explicitement, ailleurs.

                On REFERME quand meme : une base creee par une version anterieure laissait
                la connexion ouverte a tout le monde. Relancer le provisionnement la repare.
            */
            bases.cloisonner(base, utilisateur);
            journal.ecrire("PROVISION_DEJA", "Abonnement", abonnementId, base);
            return rendre(a, base, utilisateur, null,
                    "La base existait déjà : rien n'a été modifié, l'accès a été revérifié.");
        }
        // Le nom de la base et de l'utilisateur ne viennent pas de la saisie libre : ils
        // sont fabriques a partir du code client, qui n'a que des lettres et des chiffres.
        bases.creerRole(utilisateur, motDePasse);
        bases.creerBase(base, utilisateur);
        log.info("Base « {} » créée pour {}", base, c.getCode());

        a.setBaseNom(base);
        a.setProvisionneLe(OffsetDateTime.now());
        a.setUpdatedAt(OffsetDateTime.now());
        abonnements.save(a);
        journal.ecrire("PROVISION", "Abonnement", abonnementId, c.getCode() + " → base " + base);
        return rendre(a, base, utilisateur, motDePasse, a.isAvecDemonstration()
                ? "Base créée. Lancez la caisse avec cette commande : elle posera son schéma, "
                + "se réglera pour son métier et chargera la carte de démonstration au premier démarrage."
                : "Base créée. Lancez la caisse avec cette commande : elle posera son schéma et se "
                + "réglera pour son métier. Le catalogue reste vide — le client saisit le sien.");
    }

    private Map<String, String> rendre(Abonnement a, String base, String utilisateur, String motDePasse, String message) {
        Map<String, String> m = new LinkedHashMap<>();
        m.put("message", message);
        m.put("base", base);
        m.put("hote", hote);
        m.put("port", port);
        m.put("utilisateur", utilisateur);
        // Rendu une seule fois : il n'est stocke nulle part.
        if (motDePasse != null) m.put("motDePasse", motDePasse);
        m.put("module", a.getModule().name());
        m.put("avecDemonstration", Boolean.toString(a.isAvecDemonstration()));
        m.put("carteDeDemonstration", a.isAvecDemonstration() ? carte(a.getModule()) : "aucune — catalogue vide");
        m.put("commande", commande(a, base, utilisateur, motDePasse));
        return m;
    }

    /**
     * La ligne a lancer sur le poste du client.
     *
     * Elle porte tout ce que la caisse doit savoir d'elle-meme au premier demarrage : ou
     * est sa base, quel metier elle tient, sous quelle enseigne, et si elle recoit une
     * carte de demonstration. C'est cette ligne qui remplace la visite d'un technicien.
     *
     * LANG=C.UTF-8 N'EST PAS UN DETAIL. Un serveur demarre sans langue configuree lit son
     * environnement en ASCII : l'enseigne << SUPERETTE >> accentuee y perd son E, et ce
     * nom abime s'imprimerait sur chaque ticket. La caisse s'en apercoit et refuse de
     * l'enregistrer, mais autant ne pas la mettre dans cette situation.
     */
    private String commande(Abonnement a, String base, String utilisateur, String motDePasse) {
        Client c = a.getClient();
        String enseigne = (c.getEnseigne() != null && !c.getEnseigne().isBlank())
                ? c.getEnseigne() : c.getRaisonSociale();
        return "LANG=C.UTF-8"
                + " POSCAISSE_DB_HOST=" + hote + " POSCAISSE_DB_PORT=" + port
                + " POSCAISSE_DB_NAME=" + base + " POSCAISSE_DB_USER=" + utilisateur
                + (motDePasse == null ? "" : " POSCAISSE_DB_PASSWORD=" + motDePasse)
                + " POSCAISSE_PROFIL=" + a.getModule().name()
                + " POSCAISSE_ENSEIGNE='" + enseigne.replace("'", "'\\''") + "'"
                + " POSCAISSE_DEMO_DATA=" + a.isAvecDemonstration()
                + " java -jar poscaisse.jar";
    }

    /**
     * La carte que le profil installe au premier demarrage.
     *
     * Le RESTO n'a pas de fichier : sa demonstration contient des MENUS composes, que le
     * format d'import ne sait pas encore porter, et elle est donc ecrite dans la caisse.
     * Elle est GENERIQUE - un fast-food de demonstration - et surtout pas la carte d'un
     * client reel : les prix d'un restaurant ne partent pas chez ses concurrents.
     */
    public static String carte(Enums.Module module) {
        return switch (module) {
            case RESTO -> "carte fast-food intégrée";
            case CAFE -> "mistral-coffee.json";
            case SHOP -> "superette-el-baraka.json";
            case PATISSERIE -> "dar-halwa.json";
            case PARFUMERIE -> "nour-parfums.json";
            case VETEMENT -> "style-boutique.json";
        };
    }


    /**
     * pos_cli0001_cafe : le code client, le module, et rien d'autre.
     *
     * Seulement des lettres, des chiffres et des soulignes - un nom de base se retrouve
     * dans des instructions SQL qui ne se parametrent pas, et c'est la seule facon sure
     * de n'y mettre jamais rien d'inattendu.
     */
    private String nomDeBase(Client c, Abonnement a) {
        String code = c.getCode().toLowerCase().replaceAll("[^a-z0-9]", "");
        String module = a.getModule().name().toLowerCase();
        String n = (prefixe + code + "_" + module).replaceAll("[^a-z0-9_]", "");
        return n.length() > 60 ? n.substring(0, 60) : n;
    }


    private static String motDePasse() {
        byte[] b = new byte[18];
        ALEA.nextBytes(b);
        // Sans caractere qui demande d'etre echappe dans une ligne de commande.
        return Base64.getUrlEncoder().withoutPadding().encodeToString(b);
    }
}
