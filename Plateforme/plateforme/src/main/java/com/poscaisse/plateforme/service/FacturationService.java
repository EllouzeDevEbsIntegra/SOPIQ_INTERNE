package com.poscaisse.plateforme.service;

import com.poscaisse.plateforme.domain.*;
import com.poscaisse.plateforme.dto.Dtos.*;
import com.poscaisse.plateforme.repository.*;
import com.poscaisse.plateforme.security.UtilisateurCourant;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Facturer, encaisser, relancer.
 *
 * PAS DE PAIEMENT EN LIGNE, volontairement : cela demande un contrat bancaire, une
 * conformite et un mois de travail. On emet, le client vire ou depose, et le reglement se
 * saisit ici. Ce qui compte pour l'instant, c'est de savoir QUI DOIT QUOI - et un tableur
 * ne le sait jamais tres longtemps.
 *
 * LE SOLDE NE SE STOCKE PAS. Il se deduit : montant moins reglements. Un solde ecrit
 * quelque part finit toujours par ne plus correspondre a son detail, et c'est le detail
 * qu'on montre au client quand il conteste.
 */
@Service @RequiredArgsConstructor
public class FacturationService {
    private final FactureRepo factures;
    private final ReglementRepo reglements;
    private final AbonnementRepo abonnements;
    private final ClientService clients;
    private final JournalService journal;
    private final UtilisateurCourant courant;

    @Value("${plateforme.jours-avant-suspension:15}") private int joursAvantSuspension;

    @Transactional(readOnly = true)
    public List<Facture> duClient(Long clientId) { return factures.findByClientIdOrderByEmiseLeDesc(clientId); }

    @Transactional(readOnly = true)
    public Facture parId(Long id) {
        return factures.findById(id).orElseThrow(() -> ErreurMetier.introuvable("Facture"));
    }

    /**
     * Emettre la facture d'une periode.
     *
     * Le montant se calcule - prix mensuel x nombre de mois - mais reste modifiable :
     * il y a toujours un geste commercial, un mois offert, une remise de mise en service.
     * Un logiciel qui l'interdit se fait contourner par un tableur a cote.
     */
    @Transactional
    public Facture emettre(Long abonnementId, FactureRequest r) {
        courant.exige(Enums.Droit.GERER_CLIENTS);
        Abonnement a = abonnements.findById(abonnementId).orElseThrow(() -> ErreurMetier.introuvable("Abonnement"));
        LocalDate debut = r.periodeDebut() == null ? LocalDate.now().withDayOfMonth(1) : r.periodeDebut();
        LocalDate fin = r.periodeFin() == null ? debut.plusMonths(1).minusDays(1) : r.periodeFin();
        if (fin.isBefore(debut)) throw new ErreurMetier("La période finit avant de commencer.");

        long mois = Math.max(1, java.time.temporal.ChronoUnit.MONTHS.between(debut.withDayOfMonth(1), fin) + 1);
        BigDecimal montant = r.montant() != null ? r.montant()
                : a.getPrixMensuel().multiply(BigDecimal.valueOf(mois)).setScale(3, java.math.RoundingMode.HALF_UP);

        Facture f = new Facture();
        f.setClient(a.getClient());
        f.setAbonnement(a);
        f.setNumero(prochainNumero(debut));
        f.setPeriodeDebut(debut);
        f.setPeriodeFin(fin);
        f.setMontant(montant);
        f.setEmiseLe(r.emiseLe() == null ? LocalDate.now() : r.emiseLe());
        // Trente jours : l'usage entre professionnels. Le delai de suspension, lui, court
        // APRES l'echeance - on relance avant de couper.
        f.setEcheanceLe(r.echeanceLe() == null ? f.getEmiseLe().plusDays(30) : r.echeanceLe());
        f.setLibelle(r.libelle() != null ? r.libelle()
                : "Abonnement " + a.getModule() + " — " + debut + " au " + fin);
        f = factures.save(f);
        journal.ecrire("FACTURE_EMISE", "Facture", f.getId(), f.getNumero() + " — " + montant + " DT");
        return f;
    }

    private String prochainNumero(LocalDate periode) {
        String annee = String.valueOf(periode.getYear());
        return "FAC-" + annee + "-" + String.format("%04d", factures.dernierNumero(annee) + 1);
    }

    /**
     * Saisir un reglement.
     *
     * Il ne peut pas depasser ce qui reste du : un trop-percu se traite en parlant au
     * client, pas en l'ecrivant en silence dans une base. Et quand le solde tombe a zero,
     * la facture passe payee toute seule - sans quoi quelqu'un oublierait de le faire.
     */
    @Transactional
    public Facture encaisser(Long factureId, ReglementRequest r) {
        courant.exige(Enums.Droit.ENCAISSER);
        Facture f = parId(factureId);
        if (f.getStatut() == Enums.StatutFacture.ANNULEE)
            throw new ErreurMetier("Cette facture est annulée : on n'encaisse pas dessus.");
        if (r.montant() == null || r.montant().signum() <= 0)
            throw new ErreurMetier("Le montant du règlement doit être positif.");
        if (r.montant().compareTo(f.reste()) > 0)
            throw new ErreurMetier("Le règlement dépasse le reste dû (" + f.reste() + " DT). "
                    + "Corrigez le montant, ou la facture.");

        Reglement g = new Reglement();
        g.setFacture(f);
        g.setMontant(r.montant());
        g.setRecuLe(r.recuLe() == null ? LocalDate.now() : r.recuLe());
        g.setMoyen(r.moyen() == null ? Enums.MoyenReglement.VIREMENT : r.moyen());
        g.setReference(r.reference());
        g.setNote(r.note());
        courant.peutEtre().ifPresent(u -> g.setSaisiPar(u.getId()));
        f.getReglements().add(g);
        reglements.save(g);

        if (f.reste().signum() == 0) f.setStatut(Enums.StatutFacture.PAYEE);
        journal.ecrire("REGLEMENT_SAISI", "Facture", f.getId(),
                f.getNumero() + " — " + r.montant() + " DT, reste " + f.reste());
        return factures.save(f);
    }

    @Transactional
    public Facture annuler(Long factureId, String motif) {
        courant.exige(Enums.Droit.GERER_CLIENTS);
        Facture f = parId(factureId);
        if (!f.getReglements().isEmpty())
            throw new ErreurMetier("Cette facture a déjà été réglée en partie : on ne l'annule pas, on l'avoire.");
        f.setStatut(Enums.StatutFacture.ANNULEE);
        journal.ecrire("FACTURE_ANNULEE", "Facture", factureId, motif == null ? "" : motif);
        return factures.save(f);
    }

    /** Ce qui est en retard, aujourd'hui : la premiere chose qu'on regarde le matin. */
    @Transactional(readOnly = true)
    public List<Facture> enRetard() {
        return factures.findByStatutAndEcheanceLeBefore(Enums.StatutFacture.EMISE, LocalDate.now());
    }

    /**
     * Suspendre ce qui est en retard depuis trop longtemps.
     *
     * Manuel, et c'est voulu : couper un client est une decision commerciale, pas une
     * consequence automatique d'une date. La liste est preparee, quelqu'un decide.
     */
    @Transactional
    public List<String> suspendreLesRetards() {
        courant.exige(Enums.Droit.GERER_CLIENTS);
        LocalDate limite = LocalDate.now().minusDays(joursAvantSuspension);
        List<String> faits = new ArrayList<>();
        for (Facture f : factures.findByStatutAndEcheanceLeBefore(Enums.StatutFacture.EMISE, limite)) {
            if (f.getClient().getStatut() == Enums.StatutClient.SUSPENDU) continue;
            clients.suspendre(f.getClient().getId(),
                    "Impayé " + f.getNumero() + " (échéance " + f.getEcheanceLe() + ")");
            faits.add(f.getClient().getCode() + " — " + f.getNumero());
        }
        return faits;
    }
}
