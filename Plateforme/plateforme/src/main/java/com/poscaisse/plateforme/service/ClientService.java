package com.poscaisse.plateforme.service;

import com.poscaisse.plateforme.domain.*;
import com.poscaisse.plateforme.dto.Dtos.*;
import com.poscaisse.plateforme.repository.*;
import com.poscaisse.plateforme.security.UtilisateurCourant;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;

/**
 * Les clients et leurs abonnements.
 *
 * Un client se cree en PROSPECT : tant qu'il n'a rien souscrit, il n'a pas de base, pas de
 * licence et rien a payer. Il devient ACTIF a la premiere souscription - le statut suit
 * les faits, personne n'a a y penser.
 */
@Service @RequiredArgsConstructor
public class ClientService {
    private final ClientRepo clients;
    private final AbonnementRepo abonnements;
    private final LicenceService licences;
    private final JournalService journal;
    private final UtilisateurCourant courant;

    @Transactional(readOnly = true)
    public List<Client> tous() { return clients.findAllByOrderByRaisonSocialeAsc(); }

    @Transactional(readOnly = true)
    public Client parId(Long id) {
        return clients.findById(id).orElseThrow(() -> ErreurMetier.introuvable("Client"));
    }

    @Transactional
    public Client creer(ClientRequest r) {
        courant.exige(Enums.Droit.GERER_CLIENTS);
        Client c = new Client();
        // Le code se donne au telephone : CLI-0007 se lit, un identifiant de base non.
        c.setCode(String.format("CLI-%04d", clients.dernierNumero() + 1));
        appliquer(c, r);
        c = clients.save(c);
        journal.ecrire("CLIENT_CREE", "Client", c.getId(), c.getCode() + " — " + c.getRaisonSociale());
        return c;
    }

    @Transactional
    public Client modifier(Long id, ClientRequest r) {
        courant.exige(Enums.Droit.GERER_CLIENTS);
        Client c = parId(id);
        appliquer(c, r);
        c.setUpdatedAt(OffsetDateTime.now());
        journal.ecrire("CLIENT_MODIFIE", "Client", c.getId(), c.getRaisonSociale());
        return clients.save(c);
    }

    private void appliquer(Client c, ClientRequest r) {
        c.setRaisonSociale(r.raisonSociale().trim());
        c.setEnseigne(vide(r.enseigne()));
        c.setContactNom(vide(r.contactNom()));
        c.setContactTel(vide(r.contactTel()));
        c.setContactEmail(vide(r.contactEmail()));
        c.setVille(vide(r.ville()));
        c.setAdresse(vide(r.adresse()));
        c.setMatriculeFiscal(vide(r.matriculeFiscal()));
        c.setNotes(vide(r.notes()));
        if (r.statut() != null) c.setStatut(r.statut());
    }

    private static String vide(String s) { return s == null || s.isBlank() ? null : s.trim(); }

    /**
     * Souscrire : un metier, un nombre de caisses, une date de debut.
     *
     * La licence est creee dans la foulee - un abonnement sans licence serait un contrat
     * qu'aucune caisse ne peut honorer -, et le client passe ACTIF.
     */
    @Transactional
    public Abonnement souscrire(Long clientId, AbonnementRequest r) {
        courant.exige(Enums.Droit.GERER_CLIENTS);
        Client c = parId(clientId);
        Abonnement a = new Abonnement();
        a.setClient(c);
        a.setModule(r.module());
        a.setFormule(r.formule() == null ? Enums.Formule.MENSUEL : r.formule());
        a.setNbCaisses(r.nbCaisses() == null ? 1 : Math.max(1, r.nbCaisses()));
        a.setPrixMensuel(r.prixMensuel() == null ? java.math.BigDecimal.ZERO : r.prixMensuel());
        a.setDebutLe(r.debutLe() == null ? java.time.LocalDate.now() : r.debutLe());
        a.setFinLe(r.finLe());
        a = abonnements.save(a);

        licences.creerPour(a);
        if (c.getStatut() == Enums.StatutClient.PROSPECT) {
            c.setStatut(Enums.StatutClient.ACTIF);
            clients.save(c);
        }
        journal.ecrire("ABONNEMENT_CREE", "Abonnement", a.getId(),
                c.getCode() + " — " + a.getModule() + ", " + a.getNbCaisses() + " caisse(s)");
        return a;
    }

    /**
     * Suspendre : la caisse passe en lecture seule, RIEN n'est efface.
     *
     * Couper l'acces a ses propres donnees a un commercant qui a un impaye de quarante
     * dinars serait une faute : il doit pouvoir sortir son historique quoi qu'il arrive.
     */
    @Transactional
    public Client suspendre(Long clientId, String motif) {
        courant.exige(Enums.Droit.GERER_CLIENTS);
        Client c = parId(clientId);
        c.setStatut(Enums.StatutClient.SUSPENDU);
        c.setUpdatedAt(OffsetDateTime.now());
        for (Abonnement a : abonnements.findByClientId(clientId))
            if (a.getStatut() == Enums.StatutAbonnement.ACTIF) {
                a.setStatut(Enums.StatutAbonnement.SUSPENDU);
                abonnements.save(a);
            }
        journal.ecrire("CLIENT_SUSPENDU", "Client", clientId, motif == null ? "" : motif);
        return clients.save(c);
    }

    @Transactional
    public Client reactiver(Long clientId) {
        courant.exige(Enums.Droit.GERER_CLIENTS);
        Client c = parId(clientId);
        c.setStatut(Enums.StatutClient.ACTIF);
        c.setUpdatedAt(OffsetDateTime.now());
        for (Abonnement a : abonnements.findByClientId(clientId))
            if (a.getStatut() == Enums.StatutAbonnement.SUSPENDU) {
                a.setStatut(Enums.StatutAbonnement.ACTIF);
                abonnements.save(a);
            }
        journal.ecrire("CLIENT_REACTIVE", "Client", clientId, c.getRaisonSociale());
        return clients.save(c);
    }

    @Transactional(readOnly = true)
    public List<Abonnement> abonnementsDe(Long clientId) { return abonnements.findByClientId(clientId); }
}
