package com.poscaisse.plateforme.service;

import com.poscaisse.plateforme.domain.JournalEditeur;
import com.poscaisse.plateforme.repository.JournalRepo;
import com.poscaisse.plateforme.security.UtilisateurCourant;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Qui a fait quoi. Ecrit systematiquement, jamais efface. */
@Service @RequiredArgsConstructor
public class JournalService {
    private final JournalRepo repo;
    private final UtilisateurCourant courant;

    @Transactional
    public void ecrire(String action, String cibleType, Long cibleId, String details) {
        JournalEditeur j = new JournalEditeur();
        courant.peutEtre().ifPresent(u -> { j.setUserId(u.getId()); j.setUsername(u.getUsername()); });
        j.setAction(action);
        j.setCibleType(cibleType);
        j.setCibleId(cibleId);
        j.setDetails(details);
        repo.save(j);
    }

    @Transactional(readOnly = true)
    public List<JournalEditeur> dernieres() { return repo.findTop200ByOrderByCreatedAtDesc(); }
}
