package com.poscaisse.repository;

import com.poscaisse.domain.ProductStock;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductStockRepo extends JpaRepository<ProductStock, Long> {
    List<ProductStock> findByPointOfSaleId(Long posId);
    Optional<ProductStock> findByPointOfSaleIdAndProductId(Long posId, Long productId);

    /**
     * Le compteur, verrouille jusqu'a la fin de la transaction.
     *
     * Deux caisses peuvent encaisser la meme seconde. Sans ce verrou, toutes deux lisent
     * << il en reste 1 >>, toutes deux acceptent, et la derniere bouteille part deux fois.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from ProductStock s where s.pointOfSale.id = :posId and s.product.id = :productId")
    Optional<ProductStock> lock(@Param("posId") Long posId, @Param("productId") Long productId);
}
