package com.poscaisse.plateforme.repository;

import com.poscaisse.plateforme.domain.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface FactureRepo extends JpaRepository<Facture, Long> {
    Optional<Facture> findByNumero(String numero);
    List<Facture> findByClientIdOrderByEmiseLeDesc(Long clientId);
    List<Facture> findByStatutAndEcheanceLeBefore(Enums.StatutFacture statut, LocalDate date);
    /**
     * Le plus grand numero de l'annee, pour donner le suivant.
     *
     * Le compteur commence au 10e caractere : << FAC-2026-0007 >> - quatre pour << FAC- >>,
     * quatre pour l'annee, un pour le tiret. Le prendre au 9e ramenait << -0007 >>, que la
     * base convertit en -7 : la facture suivante s'appelait 0000, et la deuxieme aussi.
     */
    @Query("select coalesce(max(cast(substring(f.numero, 10) as int)), 0) from Facture f where f.numero like concat('FAC-', :annee, '-%')")
    int dernierNumero(@Param("annee") String annee);
}
