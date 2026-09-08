package com.poscaisse.security;

import com.poscaisse.exception.BusinessException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Ce qui empeche d'essayer les dix mille PIN a la suite.
 *
 * LE PROBLEME. Un PIN fait quatre chiffres. Sans compteur d'echecs, un programme les
 * essaie tous en quelques secondes et entre dans la caisse - et le jour ou l'application
 * tourne sur un serveur au lieu du PC du restaurant, il n'a meme plus besoin d'etre dans
 * la salle. Un mot de passe n'est pas mieux loti : la liste des mille plus courants tient
 * dans un fichier.
 *
 * LE CHOIX. On ne bloque pas un compte - un caissier bloque a 19 h, c'est un service perdu
 * et une caisse a l'arret. On RALENTIT : apres quelques echecs, l'adresse qui essaie doit
 * attendre, et l'attente double a chaque fois. Un humain qui se trompe deux fois ne s'en
 * apercoit pas ; un programme qui essaie dix mille combinaisons y passe des jours.
 *
 * OU CA COMPTE. Par adresse d'appel ET par cible, separement : un magasin entier derriere
 * une seule adresse ne doit pas se bloquer parce qu'un poste s'est trompe, et une attaque
 * repartie sur mille adresses contre un meme compte doit quand meme se voir.
 *
 * En memoire, volontairement : ce qui compte se mesure en minutes, une remise a zero au
 * redemarrage n'a aucune consequence, et cela evite d'ecrire en base a chaque tentative -
 * ce qui serait, en soi, une facon d'attaquer le disque.
 */
@Component
public class AntiForceBrute {

    /** En dessous, on ne fait rien : se tromper deux fois de PIN est humain. */
    private static final int SEUIL = 4;
    private static final Duration BASE = Duration.ofSeconds(2);
    private static final Duration PLAFOND = Duration.ofMinutes(5);
    /** Au-dela, le compteur repart : l'echec d'hier ne punit pas le caissier d'aujourd'hui. */
    private static final Duration OUBLI = Duration.ofMinutes(30);

    private static final class Compteur {
        int echecs;
        Instant dernier = Instant.EPOCH;
        Instant ouvertA = Instant.EPOCH;   // pas avant cet instant
    }

    private final Map<String, Compteur> compteurs = new ConcurrentHashMap<>();

    /**
     * A appeler AVANT de verifier le secret. Refuse tout de suite si la cle est en attente.
     *
     * Le message ne dit ni si le compte existe, ni combien d'essais restent : ce sont deux
     * renseignements qu'on offrirait a celui qui cherche.
     */
    public void verifier(String cle) {
        Compteur c = compteurs.get(cle);
        if (c == null) return;
        Instant maintenant = Instant.now();
        synchronized (c) {
            if (maintenant.isBefore(c.ouvertA)) {
                long s = Math.max(1, Duration.between(maintenant, c.ouvertA).toSeconds());
                throw new BusinessException(HttpStatus.TOO_MANY_REQUESTS, "TROP_D_ESSAIS",
                        "Trop de tentatives. Réessayez dans " + s + " seconde" + (s > 1 ? "s" : "") + ".");
            }
            if (Duration.between(c.dernier, maintenant).compareTo(OUBLI) > 0) c.echecs = 0;
        }
    }

    /** Un essai rate : le compteur monte, et l'attente avec lui. */
    public void echec(String cle) {
        Compteur c = compteurs.computeIfAbsent(cle, k -> new Compteur());
        Instant maintenant = Instant.now();
        synchronized (c) {
            if (Duration.between(c.dernier, maintenant).compareTo(OUBLI) > 0) c.echecs = 0;
            c.echecs++;
            c.dernier = maintenant;
            if (c.echecs >= SEUIL) {
                // 2 s, 4 s, 8 s, 16 s... plafonnees a cinq minutes.
                long secondes = Math.min(PLAFOND.toSeconds(),
                        BASE.toSeconds() << Math.min(30, c.echecs - SEUIL));
                c.ouvertA = maintenant.plusSeconds(secondes);
            }
        }
        // Une carte qui grossirait sans fin serait elle-meme une facon d'attaquer la
        // memoire : on la purge des entrees qu'on a oubliees.
        if (compteurs.size() > 5_000) purger(maintenant);
    }

    /** Reussite : on efface l'ardoise de cette cle. */
    public void succes(String cle) { compteurs.remove(cle); }

    private void purger(Instant maintenant) {
        compteurs.entrySet().removeIf(e -> Duration.between(e.getValue().dernier, maintenant).compareTo(OUBLI) > 0);
    }
}
