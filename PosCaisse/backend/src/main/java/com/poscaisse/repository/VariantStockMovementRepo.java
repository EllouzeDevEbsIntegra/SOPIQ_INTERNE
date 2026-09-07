package com.poscaisse.repository;

import com.poscaisse.domain.VariantStockMovement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;

@Repository
public interface VariantStockMovementRepo extends JpaRepository<VariantStockMovement, Long> {
    List<VariantStockMovement> findByPointOfSaleIdAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(Long posId, OffsetDateTime from);
}
