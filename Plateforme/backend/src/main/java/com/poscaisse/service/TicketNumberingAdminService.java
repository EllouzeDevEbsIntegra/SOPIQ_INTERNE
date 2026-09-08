package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.DocumentSequence;
import com.poscaisse.domain.PointOfSale;
import com.poscaisse.domain.Register;
import com.poscaisse.dto.AdminDtos.TicketCounterDto;
import com.poscaisse.dto.AdminDtos.TicketNumberingDto;
import com.poscaisse.dto.AdminDtos.TicketNumberingRequest;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.OrderRepo;
import com.poscaisse.repository.PointOfSaleRepo;
import com.poscaisse.repository.RegisterRepo;
import com.poscaisse.repository.SequenceRepo;
import com.poscaisse.service.TicketNumberService.Forme;
import com.poscaisse.service.TicketNumberService.Reglage;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * L'ecran de numerotation du back-office : montrer ce que le reglage donne AVANT de
 * l'enregistrer, et laisser reprendre la main sur le compteur.
 *
 * Un exploitant ne lit pas un gabarit, il lit un numero. Toutes les reponses d'ici
 * portent donc l'exemple exact qui sortirait de la caisse, les compteurs en cours et
 * la liste des empechements en clair. La simulation ne touche a rien : c'est le calcul
 * de la vente, sur des reglages qui ne sont pas encore ecrits.
 *
 * UN COMPTEUR N'EST PAS FORCEMENT UNIQUE. Avec une remise a zero par point de vente,
 * il y en a un par point de vente ; par caisse, un par caisse. L'ecran les liste tous,
 * et chacun se corrige separement - sans quoi << remettre le compteur a 1 >> ne voudrait
 * rien dire dans un reseau de deux boutiques.
 */
@Service @RequiredArgsConstructor
public class TicketNumberingAdminService {
    private final SettingsService settings;
    private final TicketNumberService tickets;
    private final SequenceRepo sequenceRepo;
    private final OrderRepo orderRepo;
    private final PointOfSaleRepo posRepo;
    private final RegisterRepo registerRepo;
    private final AuditService audit;

    /** Une portee vivante : sa cle, et les codes qui ont servi a la fabriquer. */
    private record Portee(String cle, String posCode, String regCode) {}

    @Transactional(readOnly = true)
    public TicketNumberingDto etat() { return vue(tickets.reglage(), true); }

    /** Le meme ecran, sur un reglage propose : rien n'est ecrit, rien n'est verrouille. */
    @Transactional(readOnly = true)
    public TicketNumberingDto simuler(TicketNumberingRequest r) {
        Reglage a = tickets.reglage();
        return vue(Reglage.of(
                r.pattern() == null ? a.pattern() : r.pattern(),
                r.resetPeriod() == null ? a.remise().name() : r.resetPeriod(),
                r.perPos() == null ? a.parPos() : r.perPos(),
                r.perRegister() == null ? a.parCaisse() : r.perRegister(),
                r.displayPattern() == null ? a.affichage() : r.displayPattern()), false);
    }

    @Transactional
    public TicketNumberingDto enregistrer(TicketNumberingRequest r) {
        Map<String, String> v = new LinkedHashMap<>();
        if (r.pattern() != null) v.put(SettingsService.TICKET_PATTERN, r.pattern().trim());
        if (r.resetPeriod() != null) v.put(SettingsService.TICKET_RESET_PERIOD, r.resetPeriod().trim().toUpperCase());
        if (r.perPos() != null) v.put(SettingsService.TICKET_PER_POS, String.valueOf(r.perPos()));
        if (r.perRegister() != null) v.put(SettingsService.TICKET_PER_REGISTER, String.valueOf(r.perRegister()));
        if (r.displayPattern() != null) v.put(SettingsService.TICKET_DISPLAY_PATTERN, r.displayPattern().trim());
        settings.update(v);          // refuse tout reglage qui fabriquerait des doublons
        return etat();
    }

    /**
     * Reprendre la main sur un compteur en cours - repartir a 1, ou demarrer a 5000 pour
     * prolonger une numerotation venue d'ailleurs.
     *
     * Le garde-fou n'est pas negociable : on refuse une valeur qui reemettrait un numero
     * deja donne. Le numero de ticket est la reference d'une vente ; deux ventes qui la
     * partagent, et c'est la comptabilite qui ment. La caisse le refuserait de toute
     * facon - mais devant le client, au moment d'encaisser.
     *
     * Seul un compteur EN COURS s'ecrit. Les compteurs des periodes passees sont montres
     * pour memoire : les corriger ne changerait aucun numero a venir.
     */
    @Transactional
    public TicketNumberingDto poserCompteur(String cle, long valeur) {
        if (valeur < 1) throw new BusinessException("Le prochain numéro doit valoir au moins 1.");
        Reglage r = tickets.reglage();
        Portee p = portees(r).stream().filter(x -> x.cle().equals(cle)).findFirst().orElseThrow(
                () -> new BusinessException("Ce compteur n’est pas celui en cours : le modifier ne changerait aucun numéro à venir."));

        Forme forme = TicketNumberService.forme(r.pattern(), p.posCode(), p.regCode());
        long deja = orderRepo.maxSequenceInShape(forme.like(), forme.debut(), forme.longueur());
        if (valeur <= deja) throw new BusinessException(
                "Le numéro " + valeur + " a déjà été imprimé sous cette forme (le plus grand est " + deja
                + "). Prenez au moins " + (deja + 1) + ", ou changez d’abord le format pour repartir sur une série neuve.");

        DocumentSequence seq = sequenceRepo.findByScopeKey(cle).orElseGet(() -> {
            DocumentSequence s = new DocumentSequence();
            s.setScopeKey(cle);
            return s;
        });
        long avant = seq.getNextValue();
        seq.setNextValue(valeur);
        sequenceRepo.save(seq);
        audit.log("TICKET_SEQUENCE_SET", "DocumentSequence", null, cle + " : " + avant + " -> " + valeur);
        return etat();
    }

    // ------------------------------------------------------------------ dedans

    private TicketNumberingDto vue(Reglage r, boolean enVigueur) {
        List<String> soucis = TicketNumberService.problemes(r);
        List<Portee> portees = portees(r);
        Portee tete = portees.get(0);

        long suivant = prochain(r, tete);
        TicketNumberService.Numero exemple = soucis.isEmpty()
                ? TicketNumberService.exemple(r, tete.posCode(), tete.regCode(), suivant) : null;

        List<TicketCounterDto> compteurs = new ArrayList<>();
        if (enVigueur) {
            Set<String> encours = new LinkedHashSet<>();
            for (Portee p : portees) {
                encours.add(p.cle());
                compteurs.add(new TicketCounterDto(p.cle(), TicketNumberService.libelle(p.cle()),
                        prochain(r, p), true,
                        TicketNumberService.exemple(r, p.posCode(), p.regCode(), prochain(r, p)).reference()));
            }
            // Les periodes passees, pour memoire : elles disent d'ou vient la numerotation.
            for (DocumentSequence s : sequenceRepo.findByScopeKeyStartingWithOrderByScopeKeyDesc(TicketNumberService.PREFIXE))
                if (!encours.contains(s.getScopeKey()))
                    compteurs.add(new TicketCounterDto(s.getScopeKey(), TicketNumberService.libelle(s.getScopeKey()),
                            s.getNextValue(), false, null));
        }
        return new TicketNumberingDto(r.pattern(), r.remise().name(), r.parPos(), r.parCaisse(), r.affichage(),
                exemple == null ? null : exemple.reference(), exemple == null ? null : exemple.affichage(),
                tete.cle(), TicketNumberService.libelle(tete.cle()), suivant, soucis, compteurs);
    }

    /**
     * Ce que ce compteur donnerait maintenant : sa valeur s'il existe, sinon celle qu'il
     * prendrait a sa creation - au-dessus de tout ce qui est deja imprime sous la meme
     * forme, jamais 1 par defaut.
     */
    private long prochain(Reglage r, Portee p) {
        return sequenceRepo.findByScopeKey(p.cle()).map(DocumentSequence::getNextValue).orElseGet(() -> {
            Forme f = TicketNumberService.forme(r.pattern(), p.posCode(), p.regCode());
            return orderRepo.maxSequenceInShape(f.like(), f.debut(), f.longueur()) + 1;
        });
    }

    /**
     * Les compteurs qui tournent aujourd'hui. Une dimension qui ne decoupe pas le
     * compteur n'en cree pas : sans remise a zero par caisse, les huit caisses du
     * reseau partagent une seule ligne.
     */
    private List<Portee> portees(Reglage r) {
        List<String> pos = r.parPos()
                ? posRepo.findAllByOrderByNameAsc().stream().filter(PointOfSale::isActive).map(PointOfSale::getCode).toList()
                : List.of(premier(posRepo.findAllByOrderByNameAsc().stream().filter(PointOfSale::isActive).map(PointOfSale::getCode).toList(), "PV01"));
        List<String> regs = r.parCaisse()
                ? registerRepo.findAllByOrderByCodeAsc().stream().filter(Register::isActive).map(Register::getCode).toList()
                : List.of(premier(registerRepo.findAllByOrderByCodeAsc().stream().filter(Register::isActive).map(Register::getCode).toList(), "C01"));
        if (pos.isEmpty()) pos = List.of("PV01");
        if (regs.isEmpty()) regs = List.of("C01");

        Map<String, Portee> vues = new LinkedHashMap<>();
        for (String p : pos)
            for (String c : regs)
                vues.putIfAbsent(TicketNumberService.cle(r, p, c), new Portee(TicketNumberService.cle(r, p, c), p, c));
        return List.copyOf(vues.values());
    }

    private static String premier(List<String> l, String defaut) { return l.isEmpty() ? defaut : l.get(0); }
}
