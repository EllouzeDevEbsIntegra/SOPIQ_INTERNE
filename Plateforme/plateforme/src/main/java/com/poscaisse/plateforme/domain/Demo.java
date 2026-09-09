package com.poscaisse.plateforme.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.Duration;
import java.time.OffsetDateTime;

/**
 * Une caisse de demonstration : un metier, un nom, un interrupteur.
 *
 * Elle n'est pas un client. Pas d'abonnement, pas de licence, pas de facture - on ne la
 * vend pas, on la montre. Ce qu'elle a en propre : une base qui lui appartient, un port
 * local, et l'heure a laquelle on l'a allumee.
 */
@Entity @Table(name = "demo") @Getter @Setter
public class Demo {

    @Id @Enumerated(EnumType.STRING) @Column(name = "module") private Enums.Module module;

    /** << demo-cafe >>, qui donne demo-cafe.pos.ebs-integra.com. */
    private String sousDomaine;
    /** Toujours prefixe << posdemo_ >> : c'est ce prefixe qui autorise sa suppression. */
    private String baseNom;
    /** Sur 127.0.0.1 uniquement. Nginx est le seul a s'y adresser. */
    private int port;

    private boolean allumee;
    private OffsetDateTime demarreeLe;
    private OffsetDateTime eteinteLe;
    private String demarreePar;

    private OffsetDateTime updatedAt = OffsetDateTime.now();

    /** Depuis combien de temps elle tourne, ou {@code null} si elle est eteinte. */
    public Duration depuis() {
        return allumee && demarreeLe != null ? Duration.between(demarreeLe, OffsetDateTime.now()) : null;
    }

    /**
     * Trop longtemps allumee ?
     *
     * Une demo oubliee un vendredi soir tourne tout le week-end et prend la memoire d'un
     * client qui, lui, paie. C'est le seul motif de cette regle : la place, pas la
     * securite.
     */
    public boolean expiree(int heuresMax) {
        Duration d = depuis();
        return d != null && d.toHours() >= heuresMax;
    }
}
