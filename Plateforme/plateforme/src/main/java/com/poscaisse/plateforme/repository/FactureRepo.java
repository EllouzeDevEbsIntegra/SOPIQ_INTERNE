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
    @Query("select coalesce(max(cast(substring(f.numero, 9) as int)), 0) from Facture f where f.numero like concat('FAC-', :annee, '-%')")
    int dernierNumero(@Param("annee") String annee);
}
