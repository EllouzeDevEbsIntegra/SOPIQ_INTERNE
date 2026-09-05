package com.poscaisse.repository;

import com.poscaisse.domain.Variant;
import com.poscaisse.domain.VariantValue;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VariantRepo extends JpaRepository<Variant, Long> {
    List<Variant> findAllByOrderBySortOrderAscIdAsc();
    List<Variant> findByActiveTrueOrderBySortOrderAscIdAsc();
    Optional<Variant> findByNameIgnoreCase(String name);

    /** Articles dont cette valeur est le defaut : desactiver l'un d'eux les rendrait invendables. */
    @Query("select p.name from Product p where p.defaultVariantValue.id = :valueId and p.active = true")
    List<String> produitsAyantPourDefaut(Long valueId);
}
