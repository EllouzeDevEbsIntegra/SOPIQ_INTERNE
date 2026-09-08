package com.poscaisse.repository;

import com.poscaisse.domain.VariantStock;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VariantStockRepo extends JpaRepository<VariantStock, Long> {
    List<VariantStock> findByPointOfSaleId(Long posId);
    Optional<VariantStock> findByPointOfSaleIdAndVariantValueId(Long posId, Long variantValueId);

    /**
     * Le compteur, verrouille jusqu'a la fin de la transaction.
     *
     * Deux caisses peuvent encaisser la meme seconde. Sans ce verrou, toutes deux lisent
     * << il reste 1 >>, toutes deux acceptent, et la derniere pate part deux fois : le
     * compteur passe a -1 et un client attend un sandwich qui n'existe pas.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from VariantStock s where s.pointOfSale.id = :posId and s.variantValue.id = :valueId")
    Optional<VariantStock> lock(@Param("posId") Long posId, @Param("valueId") Long valueId);
}
