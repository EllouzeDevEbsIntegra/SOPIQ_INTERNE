package com.poscaisse.service;

import com.poscaisse.service.TicketNumberService.Forme;
import com.poscaisse.service.TicketNumberService.Reglage;
import com.poscaisse.service.TicketNumberService.Remise;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class TicketNumberFormatTest {
    private static final LocalDate AUJOURD_HUI = LocalDate.now(ZoneId.of("Africa/Tunis"));
    private static final int AN = AUJOURD_HUI.getYear();

    private final Map<String, Long> counters = new HashMap<>();
    private long next(String key) { long v = counters.getOrDefault(key, 1L); counters.put(key, v + 1); return v; }

    private static Reglage reglage(String pattern, Remise remise, boolean parPos, boolean parCaisse) {
        return Reglage.of(pattern, remise.name(), parPos, parCaisse, "");
    }

    private static Reglage avecAffichage(String pattern, String affichage) {
        return Reglage.of(pattern, "YEARLY", true, false, affichage);
    }

    // ------------------------------------------------------------------ le texte imprime

    @Test void simpleSequence() {
        assertThat(TicketNumberService.format("{SEQ:6}", "PV01", "C01", this::next)).isEqualTo("000001");
        assertThat(TicketNumberService.format("{SEQ:6}", "PV01", "C01", this::next)).isEqualTo("000002");
    }

    @Test void posAndYearPattern() {
        assertThat(TicketNumberService.format("{POS}-{YYYY}-{SEQ:6}", "PV01", "C01", this::next)).isEqualTo("PV01-" + AN + "-000001");
        assertThat(TicketNumberService.format("{POS}-{YYYY}-{SEQ:6}", "PV02", "C01", this::next)).isEqualTo("PV02-" + AN + "-000001");
        assertThat(TicketNumberService.format("{POS}-{YYYY}-{SEQ:6}", "PV01", "C01", this::next)).isEqualTo("PV01-" + AN + "-000002");
    }

    @Test void registerAndWidthVariants() {
        assertThat(TicketNumberService.format("{REG}/{SEQ:4}", "PV01", "C02", this::next)).isEqualTo("C02/0001");
        assertThat(TicketNumberService.format("T{SEQ}", "", "", this::next)).isEqualTo("T000001");
    }

    // ------------------------------------------------------------------ la portee du compteur

    @Test void laPorteeNePorteQueCeQuiDecoupeLeCompteur() {
        assertThat(TicketNumberService.cle(reglage("{POS}-{YYYY}-{SEQ:6}", Remise.YEARLY, true, false), "PV01", "C01"))
                .isEqualTo("TICKET:PV01|" + AN);
        assertThat(TicketNumberService.cle(reglage("{SEQ:6}", Remise.NONE, false, false), "PV01", "C01"))
                .isEqualTo("TICKET:");
        assertThat(TicketNumberService.cle(reglage("{POS}{REG}-{YYYY}{MM}{DD}-{SEQ:4}", Remise.DAILY, true, true), "PV01", "C02"))
                .isEqualTo("TICKET:PV01|C02|" + AUJOURD_HUI);
    }

    /** Le point de tout ceci : imprimer l'annee sans que le compteur reparte a 1 le 1er janvier. */
    @Test void anneeImprimeeMaisCompteurContinu() {
        Reglage r = reglage("{POS}-{YYYY}-{SEQ:6}", Remise.NONE, true, false);
        assertThat(TicketNumberService.cle(r, "PV01", "C01")).isEqualTo("TICKET:PV01");
        assertThat(TicketNumberService.cle(r, "PV01", "C01")).doesNotContain(String.valueOf(AN));
    }

    /** Et l'inverse : remettre a zero chaque mois, sans forcement decouper par caisse. */
    @Test void mensuelSansDecoupageParCaisse() {
        Reglage r = reglage("{YYYY}{MM}-{SEQ:4}", Remise.MONTHLY, false, false);
        String attendu = String.format("TICKET:%04d-%02d", AN, AUJOURD_HUI.getMonthValue());
        assertThat(TicketNumberService.cle(r, "PV01", "C01")).isEqualTo(attendu);
        assertThat(TicketNumberService.cle(r, "PV02", "C09")).isEqualTo(attendu);
    }

    @Test void leLibelleSeLitDansLeBackOffice() {
        assertThat(TicketNumberService.libelle("TICKET:PV01|C02|2026-09")).isEqualTo("PV01 · C02 · 2026-09");
        assertThat(TicketNumberService.libelle("TICKET:")).isEqualTo("Compteur unique");
    }

    // ------------------------------------------------------------------ la forme, qui evite les doublons

    @Test void laFormeDesigneLesNumerosQuiPourraientSeHeurter() {
        Forme f = TicketNumberService.forme("{POS}-{YYYY}-{SEQ:6}", "PV01", "C01");
        assertThat(f.like()).isEqualTo("PV01-" + AN + "-______");
        assertThat(f.longueur()).isEqualTo(6);
        // PostgreSQL compte a partir de 1 : la tranche doit retomber sur les chiffres.
        String numero = "PV01-" + AN + "-000042";
        assertThat(numero.substring(f.debut() - 1, f.debut() - 1 + f.longueur())).isEqualTo("000042");
    }

    @Test void unCodeAvecJokerNeDeviendPasUnJoker() {
        Forme f = TicketNumberService.forme("{POS}-{SEQ:3}", "P_1", "C01");
        assertThat(f.like()).isEqualTo("P!_1-___");
    }

    @Test void leSuffixeApresLeCompteurEstGardeDansLaForme() {
        Forme f = TicketNumberService.forme("{SEQ:4}/{YY}", "PV01", "C01");
        assertThat(f.like()).isEqualTo("____/" + String.format("%02d", AN % 100));
        assertThat(f.debut()).isEqualTo(1);
    }

    // ------------------------------------------------------------------ ce qu'on refuse d'enregistrer

    @Test void toutCeQuiDecoupeLeCompteurDoitSeLireSurLeTicket() {
        assertThat(TicketNumberService.problemes(reglage("{SEQ:6}", Remise.NONE, true, false)))
                .singleElement().asString().contains("{POS}");
        assertThat(TicketNumberService.problemes(reglage("{POS}-{SEQ:6}", Remise.NONE, true, true)))
                .singleElement().asString().contains("{REG}");
        assertThat(TicketNumberService.problemes(reglage("{POS}-{SEQ:6}", Remise.YEARLY, true, false)))
                .singleElement().asString().contains("{YYYY}");
        assertThat(TicketNumberService.problemes(reglage("{YYYY}-{SEQ:6}", Remise.MONTHLY, false, false)))
                .singleElement().asString().contains("{MM}");
        assertThat(TicketNumberService.problemes(reglage("{YYYY}{MM}-{SEQ:6}", Remise.DAILY, false, false)))
                .singleElement().asString().contains("{DD}");
    }

    @Test void lesReglagesQuiTiennentPassent() {
        assertThat(TicketNumberService.problemes(reglage("{POS}-{YYYY}-{SEQ:6}", Remise.YEARLY, true, false))).isEmpty();
        assertThat(TicketNumberService.problemes(reglage("{SEQ:6}", Remise.NONE, false, false))).isEmpty();
        assertThat(TicketNumberService.problemes(reglage("{POS}{REG}-{YY}{MM}{DD}-{SEQ:3}", Remise.DAILY, true, true))).isEmpty();
        // Imprimer plus que ce qui decoupe le compteur ne pose aucun probleme.
        assertThat(TicketNumberService.problemes(reglage("{POS}-{YYYY}{MM}{DD}-{SEQ:6}", Remise.NONE, false, false))).isEmpty();
    }

    @Test void unFormatSansCompteurEstRefuse() {
        // Reglage.of retablit {SEQ:6} plutot que de laisser passer un format muet,
        // mais la regle reste dite : c'est elle qui protege une saisie a la main.
        assertThat(TicketNumberService.problemes(new Reglage("TICKET-{YYYY}", Remise.NONE, false, false, "")))
                .singleElement().asString().contains("{SEQ}");
        assertThat(Reglage.of("TICKET-{YYYY}", "NONE", false, false, "").pattern()).isEqualTo("{SEQ:6}");
    }

    // ------------------------------------------------------------------ ce qui se lit sur le papier

    /**
     * La reference peut etre longue - elle sert la comptabilite. Ce que le client lit ne
     * doit pas l'etre : les deux sortent du MEME compteur, sous deux formes.
     */
    @Test void laReferenceEstLongueEtLAffichageCourt() {
        Reglage r = avecAffichage("#-{YYYY}{MM}{DD}-{POS}-{REG}-{SEQ:6}", "{SEQ:4}");
        var n = TicketNumberService.exemple(r, "PV01", "C01", 42);
        assertThat(n.reference()).isEqualTo("#-" + String.format("%04d%02d%02d", AN, AUJOURD_HUI.getMonthValue(), AUJOURD_HUI.getDayOfMonth()) + "-PV01-C01-000042");
        assertThat(n.affichage()).isEqualTo("0042");
    }

    @Test void sansReglageDAffichageLeTicketMontreSaReference() {
        var n = TicketNumberService.exemple(avecAffichage("{POS}-{YYYY}-{SEQ:6}", ""), "PV01", "C01", 7);
        assertThat(n.affichage()).isEqualTo(n.reference()).isEqualTo("PV01-" + AN + "-000007");
    }

    @Test void lAffichagePeutPorterDAutresJetonsQueLeCompteur() {
        var n = TicketNumberService.exemple(avecAffichage("{POS}-{YYYY}-{SEQ:6}", "{REG}-{SEQ:3}"), "PV01", "C02", 8);
        assertThat(n.affichage()).isEqualTo("C02-008");
        assertThat(n.reference()).isEqualTo("PV01-" + AN + "-000008");
    }

    /** Un compteur plus large que l'affichage ne se tronque pas : un numero faux serait pire que long. */
    @Test void unCompteurPlusGrandQueLaLargeurNEstPasTronque() {
        assertThat(TicketNumberService.exemple(avecAffichage("{POS}-{YYYY}-{SEQ:6}", "{SEQ:3}"), "PV01", "C01", 12345).affichage())
                .isEqualTo("12345");
    }

    @Test void unAffichageSansCompteurEstRefuse() {
        assertThat(TicketNumberService.problemes(avecAffichage("{POS}-{YYYY}-{SEQ:6}", "N° du jour")))
                .singleElement().asString().contains("{SEQ}");
        assertThat(TicketNumberService.problemes(avecAffichage("{POS}-{YYYY}-{SEQ:6}", "{SEQ:4}"))).isEmpty();
    }
}
