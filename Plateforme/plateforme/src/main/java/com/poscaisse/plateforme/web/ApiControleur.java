package com.poscaisse.plateforme.web;

import com.poscaisse.plateforme.domain.*;
import com.poscaisse.plateforme.dto.Dtos.*;
import com.poscaisse.plateforme.repository.*;
import com.poscaisse.plateforme.service.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * L'API du back-office editeur.
 *
 * Un seul controleur : la plateforme tient en une trentaine d'appels, et les eparpiller en
 * six fichiers obligerait a ouvrir six fichiers pour savoir ce qu'elle expose.
 */
/*
    UNE TRANSACTION PAR REQUETE, posee ici et assumee.

    Les reponses portent des listes chargees a la demande - les licences d'un abonnement,
    les reglements d'une facture. Sans transaction ouverte au moment ou l'on ecrit le JSON,
    Hibernate refuse de les charger et la requete echoue en 500, ce qui est exactement ce
    qui est arrive la premiere fois. L'alternative - faire remonter des DTO entierement
    construits depuis chaque service - serait plus propre sur le papier et doublerait le
    code de la couche service pour une trentaine d'appels.

    Le cout est une connexion tenue pendant la serialisation. A l'echelle de ce
    back-office - quelques utilisateurs internes - il ne se voit pas. Le jour ou il se
    verra, ce commentaire dira quoi defaire.
*/
@RestController @RequestMapping("/api") @RequiredArgsConstructor
@org.springframework.transaction.annotation.Transactional
public class ApiControleur {
    private final AuthService auth;
    private final ClientService clients;
    private final LicenceService licences;
    private final FacturationService facturation;
    private final TableauDeBordService tableau;
    private final ProvisionnementService provisionnement;
    private final DemoService demos;
    private final JournalService journal;
    private final AbonnementRepo abonnements;
    private final FactureRepo factures;

    /** Le domaine des demos : demo-cafe + celui-ci donne l'adresse qu'on envoie au prospect. */
    @org.springframework.beans.factory.annotation.Value("${plateforme.demo.domaine}")
    private String domaineDemos;

    // ------------------------------------------------------------------ connexion
    @PostMapping("/auth/connexion") public ConnexionReponse connexion(@Valid @RequestBody ConnexionRequest r) { return auth.connexion(r); }
    @GetMapping("/auth/moi") public UtilisateurDto moi() { return auth.moi(); }
    @GetMapping("/utilisateurs") public List<UtilisateurDto> utilisateurs() { return auth.tous(); }
    @PostMapping("/utilisateurs") public UtilisateurDto creerUtilisateur(@Valid @RequestBody UtilisateurRequest r) { return auth.enregistrer(null, r); }
    @PutMapping("/utilisateurs/{id}") public UtilisateurDto modifierUtilisateur(@PathVariable Long id, @Valid @RequestBody UtilisateurRequest r) { return auth.enregistrer(id, r); }

    // ------------------------------------------------------------------ clients
    @GetMapping("/clients")
    public List<ClientDto> clients() {
        return clients.tous().stream()
                .map(c -> Mappeurs.client(c, c.getAbonnements(), c.getFactures()))
                .toList();
    }

    @GetMapping("/clients/{id}")
    public ClientDto client(@PathVariable Long id) {
        Client c = clients.parId(id);
        return Mappeurs.client(c, clients.abonnementsDe(id), factures.findByClientIdOrderByEmiseLeDesc(id));
    }

    @PostMapping("/clients") public ClientDto creer(@Valid @RequestBody ClientRequest r) { return Mappeurs.client(clients.creer(r), List.of(), List.of()); }
    @PutMapping("/clients/{id}") public ClientDto modifier(@PathVariable Long id, @Valid @RequestBody ClientRequest r) { return Mappeurs.client(clients.modifier(id, r), clients.abonnementsDe(id), factures.findByClientIdOrderByEmiseLeDesc(id)); }
    @PostMapping("/clients/{id}/suspendre") public ClientDto suspendre(@PathVariable Long id, @RequestBody(required = false) MotifRequest r) { return Mappeurs.client(clients.suspendre(id, r == null ? null : r.motif()), clients.abonnementsDe(id), List.of()); }
    @PostMapping("/clients/{id}/reactiver") public ClientDto reactiver(@PathVariable Long id) { return Mappeurs.client(clients.reactiver(id), clients.abonnementsDe(id), List.of()); }

    // ------------------------------------------------------------------ abonnements & licences
    @PostMapping("/clients/{id}/abonnements")
    public AbonnementDto souscrire(@PathVariable Long id, @Valid @RequestBody AbonnementRequest r) {
        Abonnement a = clients.souscrire(id, r);
        return Mappeurs.abonnement(a, licences.deLAbonnement(a.getId()));
    }

    @GetMapping("/abonnements/{id}")
    public AbonnementDto abonnement(@PathVariable Long id) {
        Abonnement a = abonnements.findById(id).orElseThrow(() -> ErreurMetier.introuvable("Abonnement"));
        return Mappeurs.abonnement(a, licences.deLAbonnement(id));
    }

    /**
     * Preparer la base d'un client.
     *
     * Le mot de passe n'est rendu QU'ICI, une fois : il n'est stocke nulle part. Perdu, il
     * se change ; garde quelque part, il se vole.
     */
    @PostMapping("/abonnements/{id}/provisionner")
    public java.util.Map<String, String> provisionner(@PathVariable Long id,
                                                      @RequestBody(required = false) DemonstrationRequest r) {
        return provisionnement.provisionner(id, r == null ? null : r.demonstration());
    }

    /** Partir de la carte de demonstration du metier, ou d'un catalogue vide. */
    public record DemonstrationRequest(Boolean demonstration) {}

    @PostMapping("/licences/{id}/revoquer")
    public LicenceDto revoquer(@PathVariable Long id, @RequestBody(required = false) MotifRequest r) {
        return Mappeurs.licence(licences.revoquer(id, r == null ? null : r.motif()));
    }

    /**
     * L'appel que fait une caisse en s'ouvrant. Public : elle n'a pas d'autre identifiant
     * que sa cle, et c'est justement ce qu'on verifie.
     */
    @PostMapping("/licences/verifier")
    public VerificationLicence verifier(@Valid @RequestBody VerificationRequest r) {
        return licences.verifier(r.cle(), r.empreinte(), r.libelle());
    }

    // ------------------------------------------------------------------ facturation
    @GetMapping("/clients/{id}/factures")
    public List<FactureDto> facturesDu(@PathVariable Long id) {
        return facturation.duClient(id).stream().map(Mappeurs::facture).toList();
    }

    @PostMapping("/abonnements/{id}/factures")
    public FactureDto emettre(@PathVariable Long id, @RequestBody(required = false) FactureRequest r) {
        return Mappeurs.facture(facturation.emettre(id, r == null
                ? new FactureRequest(null, null, null, null, null, null) : r));
    }

    @PostMapping("/factures/{id}/reglements")
    public FactureDto encaisser(@PathVariable Long id, @Valid @RequestBody ReglementRequest r) {
        return Mappeurs.facture(facturation.encaisser(id, r));
    }

    @PostMapping("/factures/{id}/annuler")
    public FactureDto annulerFacture(@PathVariable Long id, @RequestBody(required = false) MotifRequest r) {
        return Mappeurs.facture(facturation.annuler(id, r == null ? null : r.motif()));
    }

    @GetMapping("/factures/en-retard")
    public List<FactureDto> enRetard() { return facturation.enRetard().stream().map(Mappeurs::facture).toList(); }

    @PostMapping("/factures/suspendre-les-retards")
    public List<String> suspendreLesRetards() { return facturation.suspendreLesRetards(); }

    // ------------------------------------------------------------------ demonstrations
    @GetMapping("/demos")
    public List<DemoDto> demos() {
        return demos.etat().stream().map(d -> Mappeurs.demo(d, domaineDemos, demos.dureeMaxHeures())).toList();
    }

    @PostMapping("/demos/{module}/demarrer")
    public DemoDto demarrerDemo(@PathVariable Enums.Module module) {
        return Mappeurs.demo(demos.demarrer(module), domaineDemos, demos.dureeMaxHeures());
    }

    /**
     * Eteindre une demo, et remettre sa base a son etat initial.
     *
     * CE QUE CET APPEL EFFACE. Tout ce que le prospect a saisi pendant l'essai. C'est le
     * seul appel du back-office qui detruit des donnees sans les archiver, et c'est
     * volontaire : la demonstration suivante doit montrer la carte du metier, pas les
     * trois articles bricoles la veille. L'ecran demande confirmation en le disant avec
     * ces mots-la.
     */
    @PostMapping("/demos/{module}/arreter")
    public DemoDto arreterDemo(@PathVariable Enums.Module module) {
        return Mappeurs.demo(demos.arreter(module), domaineDemos, demos.dureeMaxHeures());
    }

    // ------------------------------------------------------------------ le reste
    @GetMapping("/tableau-de-bord") public TableauDeBord tableauDeBord() { return tableau.calculer(); }
    @GetMapping("/journal") public List<JournalDto> journal() { return journal.dernieres().stream().map(Mappeurs::journal).toList(); }
}
