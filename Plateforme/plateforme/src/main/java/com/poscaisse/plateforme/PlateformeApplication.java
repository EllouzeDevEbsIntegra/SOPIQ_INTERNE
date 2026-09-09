package com.poscaisse.plateforme;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Le back-office editeur : nos clients, leurs abonnements, leurs licences, leurs factures.
 *
 * Application SEPAREE de la caisse, et base separee. Deux raisons, et la seconde suffit :
 * ce sont deux metiers qui n'evoluent pas au meme rythme, et surtout une faille dans la
 * caisse d'un client ne doit jamais donner la liste de tous les clients.
 */
/*
    L'ORDONNANCEUR EST ACTIF POUR UNE SEULE TACHE : eteindre les demonstrations qu'on a
    oubliees (voir HorlogeDemos). Rien d'autre ici n'est periodique - la facturation et les
    suspensions restent des decisions qu'un humain prend, et le back-office ne doit pas se
    mettre a suspendre des clients tout seul pendant la nuit.
*/
@SpringBootApplication
@EnableScheduling
public class PlateformeApplication {
    public static void main(String[] args) { SpringApplication.run(PlateformeApplication.class, args); }
}
