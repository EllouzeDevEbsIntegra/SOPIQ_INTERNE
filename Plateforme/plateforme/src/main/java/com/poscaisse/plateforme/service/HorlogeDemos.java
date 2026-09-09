package com.poscaisse.plateforme.service;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Celle qui eteint les demos que personne n'a eteintes.
 *
 * POURQUOI CETTE REGLE EXISTE. Un commercial allume la demonstration patisserie un
 * vendredi a 17 h pour un rendez-vous, ferme son navigateur et part en week-end. Sans
 * personne pour appuyer sur le bouton, la caisse tourne jusqu'au lundi : soixante-cinq
 * heures de memoire et de processeur prises sur le meme serveur que les bases des clients
 * qui, eux, paient. Ce n'est pas une question de securite - le sous-domaine reste public
 * de toute facon - c'est une question de place.
 *
 * ELLE PASSE SOUVENT ET NE FAIT PRESQUE JAMAIS RIEN. Toutes les cinq minutes elle lit les
 * demos allumees - au plus six lignes - et n'ecrit que si l'une d'elles a depasse l'heure.
 * Ce rythme n'est pas la pour la precision de l'arret, il est la pour que le retard apres
 * un redemarrage du back-office se compte en minutes et non en heures : l'etat << allumee
 * depuis vendredi 17 h >> est en base, il survit au redemarrage, et la premiere passe qui
 * suit rattrape ce qui a ete manque.
 */
@Component @RequiredArgsConstructor
public class HorlogeDemos {
    private static final Logger log = LoggerFactory.getLogger(HorlogeDemos.class);

    private final DemoService demos;

    @Scheduled(fixedDelayString = "${plateforme.demo.verification:PT5M}")
    public void verifier() {
        try {
            int arretees = demos.arreterLesExpirees();
            if (arretees > 0)
                log.info("{} démonstration(s) éteinte(s) : personne ne les avait arrêtées.", arretees);
        } catch (RuntimeException e) {
            /*
                Une passe qui echoue ne doit pas emporter l'horloge. Spring arrete
                definitivement une tache planifiee dont l'execution leve : PostgreSQL
                indisponible trois minutes suffirait alors a ce que plus AUCUNE demo ne
                s'eteigne jamais, sans que rien ne le signale. On note et on repassera
                dans cinq minutes.
            */
            log.error("Vérification des démonstrations impossible cette fois : {}", e.getMessage());
        }
    }
}
