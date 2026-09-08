package com.poscaisse.plateforme.service;

import com.poscaisse.plateforme.domain.*;
import com.poscaisse.plateforme.dto.Dtos.*;
import com.poscaisse.plateforme.repository.*;
import com.poscaisse.plateforme.security.UtilisateurCourant;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

/**
 * Les licences, et la verification que fait une caisse en s'ouvrant.
 *
 * CE QUE LA VERIFICATION REPOND, et pourquoi c'est ecrit ainsi : une caisse qui demande le
 * droit d'ouvrir doit recevoir une reponse EXPLOITABLE PAR UN CAISSIER - pas un code, une
 * phrase. << Abonnement suspendu, appelez le 71 000 000 >> vaut mieux que << 403 >>, parce
 * que c'est le caissier de 19 h qui la lit, pas un developpeur.
 *
 * ON NE BLOQUE JAMAIS EN SILENCE. Une licence expiree, un poste de trop, un abonnement
 * suspendu : chaque refus dit ce qui se passe et ce qu'il faut faire.
 */
@Service @RequiredArgsConstructor
public class LicenceService {
    private static final SecureRandom ALEA = new SecureRandom();
    private static final String ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";   // sans I, O, 0, 1

    private final LicenceRepo licences;
    private final ActivationRepo activations;
    private final JournalService journal;
    private final UtilisateurCourant courant;

    /**
     * Une cle lisible a haute voix : quatre groupes de cinq, sans les caracteres qui se
     * confondent (I et 1, O et 0). Elle sera dictee au telephone un jour ou l'autre.
     */
    public static String nouvelleCle() {
        StringBuilder b = new StringBuilder();
        for (int g = 0; g < 4; g++) {
            if (g > 0) b.append('-');
            for (int i = 0; i < 5; i++) b.append(ALPHABET.charAt(ALEA.nextInt(ALPHABET.length())));
        }
        return b.toString();
    }

    @Transactional
    public Licence creerPour(Abonnement a) {
        Licence l = new Licence();
        l.setAbonnement(a);
        l.setCle(nouvelleCle());
        l.setPostesMax(a.getNbCaisses());
        // L'echeance de la licence suit celle de l'abonnement : deux dates a tenir
        // separement finiraient par diverger, et c'est le client qui le decouvrirait.
        l.setExpireLe(a.getFinLe());
        l = licences.save(l);
        journal.ecrire("LICENCE_CREEE", "Licence", l.getId(), a.getModule() + " — " + l.getCle());
        return l;
    }

    @Transactional(readOnly = true)
    public List<Licence> deLAbonnement(Long abonnementId) { return licences.findByAbonnementId(abonnementId); }

    @Transactional
    public Licence revoquer(Long id, String motif) {
        courant.exige(Enums.Droit.GERER_CLIENTS);
        Licence l = licences.findById(id).orElseThrow(() -> ErreurMetier.introuvable("Licence"));
        l.setRevoquee(true);
        journal.ecrire("LICENCE_REVOQUEE", "Licence", id, motif == null ? "" : motif);
        return licences.save(l);
    }

    /**
     * Le poste demande a ouvrir. C'est le seul appel que fait une caisse ici.
     *
     * L'empreinte identifie la machine : deux ouvertures sur le meme poste ne consomment
     * qu'une place, et un poste remplace se voit dans la liste plutot que de gonfler le
     * compteur en silence.
     */
    @Transactional
    public VerificationLicence verifier(String cle, String empreinte, String libelle) {
        Licence l = licences.findByCle(cle == null ? "" : cle.trim().toUpperCase()).orElse(null);
        if (l == null) return VerificationLicence.refus("Licence inconnue. Vérifiez la clé saisie.");

        l.setDerniereVerif(OffsetDateTime.now());
        licences.save(l);

        if (l.isRevoquee()) return VerificationLicence.refus("Licence révoquée. Contactez votre fournisseur.");

        Abonnement a = l.getAbonnement();
        Client c = a.getClient();
        if (c.getStatut() == Enums.StatutClient.RESILIE)
            return VerificationLicence.refus("Abonnement résilié. Contactez votre fournisseur.");
        if (c.getStatut() == Enums.StatutClient.SUSPENDU || a.getStatut() == Enums.StatutAbonnement.SUSPENDU)
            return VerificationLicence.lectureSeule("Abonnement suspendu : la caisse est en lecture seule. "
                    + "Vos données sont intactes — contactez votre fournisseur pour rétablir le service.");
        if (l.getExpireLe() != null && l.getExpireLe().isBefore(LocalDate.now()))
            return VerificationLicence.refus("Licence expirée le " + l.getExpireLe() + ". Contactez votre fournisseur.");

        String emp = empreinte == null || empreinte.isBlank() ? null : empreinte.trim();
        if (emp != null) {
            LicenceActivation act = activations.findByLicenceIdAndEmpreinte(l.getId(), emp).orElse(null);
            if (act == null) {
                if (activations.countByLicenceId(l.getId()) >= l.getPostesMax())
                    return VerificationLicence.refus("Cette licence couvre " + l.getPostesMax()
                            + " caisse(s), toutes déjà utilisées. Contactez votre fournisseur pour en ajouter une.");
                act = new LicenceActivation();
                act.setLicence(l);
                act.setEmpreinte(emp);
                act.setLibelle(libelle);
                journal.ecrire("LICENCE_ACTIVEE", "Licence", l.getId(), "Nouveau poste : " + (libelle == null ? emp : libelle));
            }
            act.setDerniereLe(OffsetDateTime.now());
            if (libelle != null && !libelle.isBlank()) act.setLibelle(libelle.trim());
            activations.save(act);
        }
        return VerificationLicence.ok(c.getRaisonSociale(), a.getModule(), a.getNbCaisses(), l.getExpireLe());
    }
}
