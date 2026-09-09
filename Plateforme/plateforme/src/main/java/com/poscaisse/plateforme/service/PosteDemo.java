package com.poscaisse.plateforme.service;

import com.poscaisse.plateforme.domain.Demo;

/**
 * Allumer et eteindre le processus d'une caisse de demonstration.
 *
 * POURQUOI UNE INTERFACE POUR TROIS METHODES. Ce qui est derriere lance un vrai processus
 * sur le serveur, avec sudo. Un test qui passerait par la demanderait une machine equipee
 * du script enveloppe et d'une regle sudo - autant dire qu'il ne tournerait jamais, et que
 * la regle des vingt-quatre heures ne serait verifiee par personne. La couture est ici :
 * en test, un {@code PosteDemo} qui note les appels sans rien lancer laisse le reste du
 * service - la base refaite a neuf, l'expiration, les droits - s'executer pour de vrai.
 */
public interface PosteDemo {

    void demarrer(Demo d);

    void arreter(Demo d);

    /** Le processus repond-il ? Sert a constater, jamais a decider d'agir. */
    boolean tourne(Demo d);
}
