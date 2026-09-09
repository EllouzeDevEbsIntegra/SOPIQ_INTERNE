package com.poscaisse.plateforme.service;

import com.poscaisse.plateforme.domain.Demo;
import com.poscaisse.plateforme.domain.Enums;
import com.poscaisse.plateforme.repository.DemoRepo;
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
import java.util.List;

/**
 * Les six caisses de demonstration : les allumer, les eteindre, les oublier sans risque.
 *
 * CE QU'EST UNE DEMO ICI. Un metier, une base a elle, un port local, un interrupteur.
 * Pas de client, pas d'abonnement, pas de licence : on ne la vend pas, on la montre. Un
 * commercial l'allume avant un rendez-vous, envoie l'adresse au prospect, et n'y repense
 * plus - c'est l'horloge qui l'eteint.
 *
 * ETEINDRE EFFACE, ET C'EST LE POINT DELICAT. La base repart a son etat de demonstration
 * initial : ce que le prospect a saisi pendant l'essai disparait. C'est voulu - la demo
 * suivante doit montrer une carte propre, pas les trois articles bricoles la veille - mais
 * cela doit etre dit clairement a celui qui appuie, et l'ecran le dit.
 */
@Service @RequiredArgsConstructor
public class DemoService {
    private static final Logger log = LoggerFactory.getLogger(DemoService.class);
    private static final SecureRandom ALEA = new SecureRandom();

    private final DemoRepo demos;
    private final BasesPostgres bases;
    private final PosteDemo poste;
    private final JournalService journal;
    private final UtilisateurCourant courant;

    /**
     * Au bout de combien d'heures une demo s'eteint toute seule.
     *
     * Vingt-quatre par defaut : assez pour un essai qui se poursuit le lendemain matin,
     * trop peu pour qu'un oubli du vendredi tienne jusqu'au lundi.
     */
    @Value("${plateforme.demo.duree-max-heures:24}") private int dureeMaxHeures;

    public int dureeMaxHeures() { return dureeMaxHeures; }

    @Transactional(readOnly = true)
    public List<Demo> etat() { return demos.findAllByOrderByModuleAsc(); }

    /**
     * Allumer la demo d'un metier.
     *
     * Idempotent sur la base : si elle est deja la, on ne la refait pas. Un commercial qui
     * appuie deux fois parce que la page a mis trois secondes ne doit pas effacer la demo
     * qu'il est en train de montrer.
     */
    @Transactional
    public Demo demarrer(Enums.Module module) {
        courant.exige(Enums.Droit.GERER_CLIENTS);
        Demo d = demos.findById(module).orElseThrow(() -> ErreurMetier.introuvable("Démo"));

        if (!bases.existe(d.getBaseNom())) {
            /*
                LE ROLE SE CREE, LE MOT DE PASSE NE SE REJOUE PAS.

                Il est ecrit une fois pour toutes dans le fichier de service systemd du
                poste, cote serveur ; le back-office ne le relit jamais et n'a aucune
                raison de le changer. creerRole ne fait donc rien si le role est deja la -
                ce qui arrive apres chaque remise a neuf, puisque celle-ci detruit la base
                et garde le role. Lui donner un nouveau mot de passe ici casserait le
                demarrage suivant, silencieusement, jusqu'a ce que quelqu'un lise les
                journaux de systemd.
            */
            bases.creerRole(d.getBaseNom(), motDePasse());
            bases.creerBase(d.getBaseNom(), d.getBaseNom());
            log.info("Base de démonstration « {} » créée.", d.getBaseNom());
        }

        poste.demarrer(d);

        d.setAllumee(true);
        d.setDemarreeLe(OffsetDateTime.now());
        d.setEteinteLe(null);
        d.setDemarreePar(courant.exigeConnecte().getUsername());
        d.setUpdatedAt(OffsetDateTime.now());
        demos.save(d);
        journal.ecrire("DEMO_START", "Demo", null, module + " → " + d.getSousDomaine());
        return d;
    }

    /** Eteindre la demo d'un metier, et remettre sa base a neuf. */
    @Transactional
    public Demo arreter(Enums.Module module) {
        courant.exige(Enums.Droit.GERER_CLIENTS);
        Demo d = demos.findById(module).orElseThrow(() -> ErreurMetier.introuvable("Démo"));
        eteindre(d, "à la demande");
        return d;
    }

    /**
     * Eteindre celles qui trainent, et rendre combien.
     *
     * ELLE N'EXIGE AUCUN DROIT, ET C'EST VOULU : personne ne l'appelle. C'est l'horloge,
     * qui n'est connectee sous aucun compte - {@code courant.exige} y echouerait sur
     * << Authentification requise >>, et la regle des vingt-quatre heures ne s'appliquerait
     * jamais. Elle ne prend aucun parametre venu de l'exterieur non plus : elle ne peut
     * donc rien eteindre que le temps n'ait deja condamne.
     */
    @Transactional
    public int arreterLesExpirees() {
        int arretees = 0;
        for (Demo d : demos.findByAllumeeTrue()) {
            if (!d.expiree(dureeMaxHeures)) continue;
            eteindre(d, "expirée après " + dureeMaxHeures + " h");
            arretees++;
        }
        return arretees;
    }

    // ------------------------------------------------------------------ mecanique

    /**
     * L'ORDRE DES DEUX GESTES EST LA SEULE CHOSE QUI COMPTE ICI.
     *
     * On coupe D'ABORD le processus, on refait la base ENSUITE. Dans l'autre sens, la
     * caisse est encore connectee quand on supprime : DROP DATABASE ... WITH (FORCE) la
     * jette dehors, elle se retrouve devant une base qui n'existe plus, ecrit ses erreurs
     * en boucle, et selon le moment ou elle en etait, recree la moitie de son schema dans
     * la base neuve que l'on vient de reconstruire. On obtiendrait une demonstration a
     * moitie faite, ce qui est pire qu'aucune.
     */
    private void eteindre(Demo d, String motif) {
        poste.arreter(d);

        // Une demo jamais allumee sur ce serveur n'a pas encore de base : il n'y a rien a
        // remettre a neuf, et CREATE DATABASE ... OWNER echouerait sur un role absent.
        if (bases.existe(d.getBaseNom())) bases.remettreANeuf(d.getBaseNom(), d.getBaseNom());

        d.setAllumee(false);
        d.setEteinteLe(OffsetDateTime.now());
        d.setUpdatedAt(OffsetDateTime.now());
        demos.save(d);
        journal.ecrire("DEMO_STOP", "Demo", null, d.getModule() + " — " + motif + ", base remise à neuf");
        log.info("Démo « {} » éteinte ({}).", d.getModule(), motif);
    }

    /** Comme pour un client : tire au sort, jamais relu, jamais journalise. */
    private static String motDePasse() {
        byte[] b = new byte[18];
        ALEA.nextBytes(b);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(b);
    }
}
