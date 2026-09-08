package com.poscaisse.service;

import com.poscaisse.domain.DocumentSequence;
import com.poscaisse.domain.Enums;
import com.poscaisse.domain.PointOfSale;
import com.poscaisse.repository.OrderRepo;
import com.poscaisse.repository.SequenceRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Le numero de ticket : ce qui s'imprime, et quand le compteur repart a 1.
 *
 * DEUX REGLAGES, PAS UN
 * Le format ({POS}-{YYYY}-{SEQ:6}) dit ce que le client lit sur son ticket. La portee
 * dit sur quoi le compteur est tenu : par point de vente, par caisse, et sur quelle
 * periode - jour, mois, annee, ou jamais. Les deux etaient confondus : le compteur
 * repartait a 1 des que le prefixe imprime changeait, si bien qu'on ne pouvait pas
 * imprimer l'annee sans remettre a zero chaque 1er janvier, ni remettre a zero chaque
 * jour sans imprimer la date. Ils sont maintenant separes, et l'un ne se devine plus.
 *
 * POURQUOI DEUX NUMEROS NE PEUVENT PAS SE REPETER
 * Un numero vaut prefixe imprime + compteur. Dans une meme portee le compteur ne
 * repasse jamais par la meme valeur ; deux tickets ne peuvent donc se heurter que
 * s'ils viennent de portees DIFFERENTES qui impriment le MEME prefixe. D'ou la regle
 * tenue par {@link #problemes} : tout ce qui decoupe le compteur doit se lire sur le
 * ticket. Une caisse par compteur sans {REG} imprime, et les deux caisses sortiraient
 * le meme numero le meme jour.
 *
 * ET QUAND LE REGLAGE CHANGE
 * Un compteur qui vient d'etre cree ne part pas de 1 : il part au-dessus du plus grand
 * numero deja imprime sous la meme forme ({@link OrderRepo#maxSequenceInShape}). Sans
 * cela, passer d'une remise a zero annuelle a mensuelle en cours d'annee reemettrait
 * des numeros deja donnes - et la contrainte d'unicite sur sale_order.ticket_number
 * ferait echouer la vente, en pleine caisse. La relecture coute une requete par
 * compteur cree, c'est-a-dire au pire une par jour.
 */
@Service @RequiredArgsConstructor
public class TicketNumberService {
    private static final Pattern SEQ = Pattern.compile("\\{SEQ(?::(\\d+))?}");
    public static final ZoneId ZONE = ZoneId.of("Africa/Tunis");
    /** Prefixe des compteurs de tickets dans document_sequence, pour les distinguer des reglements. */
    public static final String PREFIXE = "TICKET:";

    private final SequenceRepo sequenceRepo;
    private final OrderRepo orderRepo;
    private final SettingsService settings;

    /** Sur quoi le compteur repart a 1. */
    public enum Remise { NONE, DAILY, MONTHLY, YEARLY }

    /**
     * Les reglages qui font un numero, lus ensemble : ils ne se jugent pas separement.
     *
     * << pattern >> est la REFERENCE, celle qui est enregistree et qui doit rester unique.
     * << affichage >> est ce que le caissier et le client lisent : vide, c'est la reference
     * elle-meme ; sinon un format plus court, tire du meme compteur. Le detail complet
     * reste en base pour la comptabilite, sans encombrer le ticket.
     */
    public record Reglage(String pattern, Remise remise, boolean parPos, boolean parCaisse, String affichage) {
        public static Reglage of(String pattern, String remise, boolean parPos, boolean parCaisse, String affichage) {
            Remise r;
            try { r = Remise.valueOf(remise == null ? "NONE" : remise.trim().toUpperCase()); }
            catch (IllegalArgumentException e) { r = Remise.NONE; }
            return new Reglage(pattern == null || !pattern.contains("{SEQ") ? "{SEQ:6}" : pattern, r, parPos, parCaisse,
                    affichage == null ? "" : affichage.trim());
        }
    }

    /** Ce qu'une vente emporte : sa reference unique, et ce qui s'ecrit sous les yeux. */
    public record Numero(String reference, String affichage) {}

    @Transactional(propagation = Propagation.MANDATORY)
    public Numero next(PointOfSale pos, String registerCode) {
        Reglage r = reglage();
        String posCode = pos == null ? "" : pos.getCode();
        Forme forme = forme(r.pattern(), posCode, registerCode);
        long[] tire = new long[1];
        String reference = format(r.pattern(), posCode, registerCode,
                ignore -> (tire[0] = valeurSuivante(cle(r, posCode, registerCode), forme)));
        // Le compteur n'est tire QU'UNE FOIS : l'affichage rejoue le meme numero sous une
        // autre forme, il ne demande pas le suivant - sinon un ticket sur deux serait saute.
        return new Numero(reference, affichage(r, posCode, registerCode, tire[0], reference));
    }

    /** Ce qui s'ecrit sur le ticket et a l'ecran pour un compteur donne. */
    public static String affichage(Reglage r, String posCode, String registerCode, long valeur, String reference) {
        return r.affichage().isBlank() ? reference : format(r.affichage(), posCode, registerCode, k -> valeur);
    }

    /** Le reglage courant, tel qu'il est enregistre. */
    public Reglage reglage() {
        return Reglage.of(settings.get(SettingsService.TICKET_PATTERN),
                settings.get(SettingsService.TICKET_RESET_PERIOD),
                settings.getBoolean(SettingsService.TICKET_PER_POS),
                settings.getBoolean(SettingsService.TICKET_PER_REGISTER),
                settings.get(SettingsService.TICKET_DISPLAY_PATTERN));
    }

    /**
     * La cle du compteur : uniquement ce qui le decoupe, jamais ce qui n'est qu'imprime.
     * C'est ce qui permet d'imprimer l'annee sans repartir a 1 le 1er janvier.
     */
    public static String cle(Reglage r, String posCode, String registerCode) {
        List<String> parts = new ArrayList<>();
        if (r.parPos()) parts.add(posCode == null || posCode.isBlank() ? "-" : posCode);
        if (r.parCaisse()) parts.add(registerCode == null || registerCode.isBlank() ? "-" : registerCode);
        String p = periode(r.remise(), LocalDate.now(ZONE));
        if (!p.isEmpty()) parts.add(p);
        return PREFIXE + String.join("|", parts);
    }

    public static String periode(Remise remise, LocalDate jour) {
        return switch (remise) {
            case YEARLY -> String.format("%04d", jour.getYear());
            case MONTHLY -> String.format("%04d-%02d", jour.getYear(), jour.getMonthValue());
            case DAILY -> jour.toString();
            case NONE -> "";
        };
    }

    /** Comment se lit la cle dans le back-office : << PV01 · caisse C01 · 2026-09 >>. */
    public static String libelle(String cle) {
        String reste = cle.startsWith(PREFIXE) ? cle.substring(PREFIXE.length()) : cle;
        return reste.isEmpty() ? "Compteur unique" : reste.replace("|", " · ");
    }

    private long valeurSuivante(String cle, Forme forme) {
        DocumentSequence seq = sequenceRepo.lockByKey(cle).orElseGet(() -> {
            DocumentSequence s = new DocumentSequence();
            s.setScopeKey(cle);
            // Au-dessus de ce qui est deja sorti sous cette forme, jamais betement a 1.
            s.setNextValue(orderRepo.maxSequenceInShape(forme.like(), forme.debut(), forme.longueur()) + 1);
            return sequenceRepo.saveAndFlush(s);
        });
        long v = seq.getNextValue();
        seq.setNextValue(v + 1);
        sequenceRepo.save(seq);
        return v;
    }

    /**
     * Numero de reglement de compte, sur une sequence distincte de celle des tickets :
     * melanger les deux ferait des trous dans la numerotation des ventes. Clients et
     * livreurs ont chacun leur serie, pour que deux comptes ne se renvoient pas le
     * meme numero de piece.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public String nextAccountPayment(Enums.AccountParty party) {
        boolean courier = party == Enums.AccountParty.COURIER;
        LocalDate today = LocalDate.now(ZONE);
        String scopeKey = (courier ? "COURIER_PAYMENT:" : "CUSTOMER_PAYMENT:") + today.getYear();
        DocumentSequence seq = sequenceRepo.lockByKey(scopeKey).orElseGet(() -> {
            DocumentSequence s = new DocumentSequence();
            s.setScopeKey(scopeKey);
            s.setNextValue(1);
            return sequenceRepo.saveAndFlush(s);
        });
        long v = seq.getNextValue();
        seq.setNextValue(v + 1);
        sequenceRepo.save(seq);
        return String.format(courier ? "RLV-%d-%06d" : "REG-%d-%06d", today.getYear(), v);
    }

    public interface SeqSource { long next(String scopeKey); }

    public static String format(String pattern, String posCode, String registerCode, SeqSource source) {
        String resolved = resoudre(pattern, posCode, registerCode, LocalDate.now(ZONE));
        Matcher m = SEQ.matcher(resolved);
        if (!m.find()) return resolved;
        int width = m.group(1) == null ? 6 : Integer.parseInt(m.group(1));
        String scopeKey = PREFIXE + resolved.replace(m.group(0), "#");
        String num = String.format("%0" + width + "d", source.next(scopeKey));
        return resolved.substring(0, m.start()) + num + resolved.substring(m.end());
    }

    private static String resoudre(String pattern, String posCode, String registerCode, LocalDate jour) {
        return pattern
                .replace("{POS}", posCode == null ? "" : posCode)
                .replace("{REG}", registerCode == null ? "" : registerCode)
                .replace("{YYYY}", String.valueOf(jour.getYear()))
                .replace("{YY}", String.format("%02d", jour.getYear() % 100))
                .replace("{MM}", String.format("%02d", jour.getMonthValue()))
                .replace("{DD}", String.format("%02d", jour.getDayOfMonth()));
    }

    /**
     * La FORME d'un numero aujourd'hui : le texte imprime, le compteur remplace par des
     * jokers. Elle dit exactement quels numeros peuvent se heurter au prochain - ce
     * sont ceux qui s'ecrivent pareil - et sert donc a placer un compteur neuf.
     */
    public record Forme(String like, int debut, int longueur) {}

    public static Forme forme(String pattern, String posCode, String registerCode) {
        String resolved = resoudre(pattern, posCode, registerCode, LocalDate.now(ZONE));
        Matcher m = SEQ.matcher(resolved);
        if (!m.find()) return new Forme(echapper(resolved), 1, 0);
        int width = m.group(1) == null ? 6 : Integer.parseInt(m.group(1));
        String like = echapper(resolved.substring(0, m.start())) + "_".repeat(width)
                    + echapper(resolved.substring(m.end()));
        return new Forme(like, m.start() + 1, width);   // substring() de PostgreSQL compte a partir de 1
    }

    /** Un code de caisse contenant % ou _ ferait de LIKE un joker : on les neutralise. */
    private static String echapper(String s) {
        return s.replace("!", "!!").replace("%", "!%").replace("_", "!_");
    }

    /** Le numero qui sortirait, pour montrer le reglage avant de l'enregistrer. */
    public static Numero exemple(Reglage r, String posCode, String registerCode, long valeur) {
        String reference = format(r.pattern(), posCode, registerCode, k -> valeur);
        return new Numero(reference, affichage(r, posCode, registerCode, valeur, reference));
    }

    /**
     * Ce qui empeche ce reglage de tenir. Tout ce qui decoupe le compteur doit se lire
     * sur le ticket : sinon deux portees impriment le meme numero, et la vente est
     * refusee au moment de l'encaissement - le pire endroit pour l'apprendre.
     */
    public static List<String> problemes(Reglage r) {
        List<String> l = new ArrayList<>();
        String p = r.pattern();
        boolean annee = p.contains("{YYYY}") || p.contains("{YY}");
        if (!p.contains("{SEQ")) l.add("Le format doit contenir {SEQ} : sans compteur, tous les tickets porteraient le même numéro.");
        if (r.parPos() && !p.contains("{POS}"))
            l.add("Un compteur par point de vente exige {POS} dans le format, sinon deux points de vente sortiraient le même numéro.");
        if (r.parCaisse() && !p.contains("{REG}"))
            l.add("Un compteur par caisse exige {REG} dans le format, sinon deux caisses sortiraient le même numéro.");
        if (r.remise() == Remise.YEARLY && !annee)
            l.add("Une remise à zéro annuelle exige {YYYY} ou {YY} dans le format, sinon les numéros de l’an prochain répéteraient ceux de cette année.");
        if (r.remise() == Remise.MONTHLY && (!annee || !p.contains("{MM}")))
            l.add("Une remise à zéro mensuelle exige {MM} et {YYYY} (ou {YY}) dans le format, sinon deux mois porteraient les mêmes numéros.");
        if (r.remise() == Remise.DAILY && (!annee || !p.contains("{MM}") || !p.contains("{DD}")))
            l.add("Une remise à zéro journalière exige {DD}, {MM} et {YYYY} (ou {YY}) dans le format, sinon deux jours porteraient les mêmes numéros.");
        // L'affichage n'a pas a etre unique - c'est la reference qui l'est - mais sans
        // compteur il serait identique sur tous les tickets, et ne designerait plus rien.
        if (!r.affichage().isBlank() && !r.affichage().contains("{SEQ"))
            l.add("L’affichage doit contenir {SEQ} : sans compteur, tous les tickets afficheraient la même chose.");
        return l;
    }
}
