package com.poscaisse.plateforme.service;

import com.poscaisse.plateforme.domain.*;
import com.poscaisse.plateforme.dto.Dtos.*;
import com.poscaisse.plateforme.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;

/**
 * Ce qu'on regarde le matin, en un seul appel.
 *
 * Quatre chiffres qui commandent la journee : combien de clients, combien de caisses, ce
 * que le parc rapporte chaque mois, et surtout QUI EST EN RETARD - avec les factures, pas
 * seulement leur nombre : un compteur sans les noms oblige a ouvrir un autre ecran.
 */
@Service @RequiredArgsConstructor
public class TableauDeBordService {
    private final ClientRepo clients;
    private final AbonnementRepo abonnements;
    private final FactureRepo factures;
    private final FacturationService facturation;

    @Transactional(readOnly = true)
    public TableauDeBord calculer() {
        List<Client> tous = clients.findAll();
        List<Abonnement> abos = abonnements.findByStatut(Enums.StatutAbonnement.ACTIF);
        BigDecimal recurrent = abos.stream().map(Abonnement::getPrixMensuel)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        long caisses = abos.stream().mapToLong(Abonnement::getNbCaisses).sum();

        List<Facture> retards = facturation.enRetard();
        BigDecimal montantRetard = retards.stream().map(Facture::reste).reduce(BigDecimal.ZERO, BigDecimal::add);

        List<AbonnementDto> derniers = abonnements.findAll().stream()
                .sorted(Comparator.comparing(Abonnement::getCreatedAt).reversed())
                .limit(8).map(a -> Mappeurs.abonnement(a, List.of())).toList();

        return new TableauDeBord(
                tous.size(),
                tous.stream().filter(c -> c.getStatut() == Enums.StatutClient.ACTIF).count(),
                tous.stream().filter(c -> c.getStatut() == Enums.StatutClient.SUSPENDU).count(),
                abos.size(), caisses, recurrent,
                retards.size(), montantRetard,
                retards.stream().map(Mappeurs::facture).toList(),
                derniers);
    }
}
