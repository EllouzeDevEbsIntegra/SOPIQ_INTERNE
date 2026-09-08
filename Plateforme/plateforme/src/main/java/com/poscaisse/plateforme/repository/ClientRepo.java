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
public interface ClientRepo extends JpaRepository<Client, Long> {
    Optional<Client> findByCode(String code);
    List<Client> findAllByOrderByRaisonSocialeAsc();
    List<Client> findByStatut(Enums.StatutClient statut);
    @Query("select coalesce(max(cast(substring(c.code, 5) as int)), 0) from Client c where c.code like 'CLI-%'")
    int dernierNumero();
}
