package com.poscaisse.repository;

import com.poscaisse.domain.ProductStockMovement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;

@Repository
public interface ProductStockMovementRepo extends JpaRepository<ProductStockMovement, Long> {
    List<ProductStockMovement> findByPointOfSaleIdAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(
            Long posId, OffsetDateTime depuis);
    List<ProductStockMovement> findTop50ByProductIdOrderByCreatedAtDesc(Long productId);
}
