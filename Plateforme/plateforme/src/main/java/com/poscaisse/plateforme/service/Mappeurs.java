package com.poscaisse.plateforme.service;

import com.poscaisse.plateforme.domain.*;
import com.poscaisse.plateforme.dto.Dtos.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/** Des entites vers ce que l'API montre. Rien d'autre ne franchit la frontiere. */
public class Mappeurs {

    public static ClientDto client(Client c, List<Abonnement> abos, List<Facture> factures) {
        BigDecimal du = factures == null ? BigDecimal.ZERO : factures.stream()
                .filter(f -> f.getStatut() == Enums.StatutFacture.EMISE)
                .map(Facture::reste).reduce(BigDecimal.ZERO, BigDecimal::add);
        return new ClientDto(c.getId(), c.getCode(), c.getRaisonSociale(), c.getEnseigne(), c.getContactNom(),
                c.getContactTel(), c.getContactEmail(), c.getVille(), c.getAdresse(), c.getMatriculeFiscal(),
                c.getStatut(), c.getNotes(), c.getCreatedAt(),
                abos == null ? List.of() : abos.stream().map(a -> abonnement(a, List.of())).toList(), du);
    }

    public static AbonnementDto abonnement(Abonnement a, List<Licence> licences) {
        Client c = a.getClient();
        return new AbonnementDto(a.getId(), c == null ? null : c.getId(), c == null ? null : c.getCode(),
                c == null ? null : c.getRaisonSociale(), a.getModule(), a.getFormule(), a.getNbCaisses(),
                a.getPrixMensuel(), a.getDebutLe(), a.getFinLe(), a.getStatut(), a.getBaseNom(), a.getUrlClient(),
                a.getVersion(), a.getProvisionneLe(),
                licences == null ? List.of() : licences.stream().map(Mappeurs::licence).toList());
    }

    public static LicenceDto licence(Licence l) {
        List<ActivationDto> act = l.getActivations().stream()
                .map(x -> new ActivationDto(x.getId(), x.getEmpreinte(), x.getLibelle(), x.getPremiereLe(), x.getDerniereLe()))
                .toList();
        return new LicenceDto(l.getId(), l.getCle(), l.getPostesMax(), l.getExpireLe(), l.isRevoquee(),
                l.getDerniereVerif(), act.size(), act);
    }

    public static FactureDto facture(Facture f) {
        Client c = f.getClient();
        boolean retard = f.getStatut() == Enums.StatutFacture.EMISE
                && f.getEcheanceLe() != null && f.getEcheanceLe().isBefore(LocalDate.now());
        return new FactureDto(f.getId(), c == null ? null : c.getId(), c == null ? null : c.getCode(),
                c == null ? null : c.getRaisonSociale(),
                f.getAbonnement() == null ? null : f.getAbonnement().getId(),
                f.getNumero(), f.getPeriodeDebut(), f.getPeriodeFin(), f.getMontant(), f.regle(), f.reste(),
                f.getEmiseLe(), f.getEcheanceLe(), f.getStatut(), retard, f.getLibelle(),
                f.getReglements().stream().map(Mappeurs::reglement).toList());
    }

    public static ReglementDto reglement(Reglement r) {
        return new ReglementDto(r.getId(), r.getMontant(), r.getRecuLe(), r.getMoyen(), r.getReference(),
                r.getNote(), r.getCreatedAt());
    }

    public static JournalDto journal(JournalEditeur j) {
        return new JournalDto(j.getId(), j.getUsername(), j.getAction(), j.getCibleType(), j.getCibleId(),
                j.getDetails(), j.getCreatedAt());
    }
}
