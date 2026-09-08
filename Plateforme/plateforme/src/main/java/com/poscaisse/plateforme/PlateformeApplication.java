package com.poscaisse.plateforme;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Le back-office editeur : nos clients, leurs abonnements, leurs licences, leurs factures.
 *
 * Application SEPAREE de la caisse, et base separee. Deux raisons, et la seconde suffit :
 * ce sont deux metiers qui n'evoluent pas au meme rythme, et surtout une faille dans la
 * caisse d'un client ne doit jamais donner la liste de tous les clients.
 */
@SpringBootApplication
public class PlateformeApplication {
    public static void main(String[] args) { SpringApplication.run(PlateformeApplication.class, args); }
}
