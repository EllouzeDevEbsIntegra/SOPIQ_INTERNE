package com.poscaisse.repository;

import com.poscaisse.domain.*;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderLineRepo extends JpaRepository<OrderLine, Long> {
    long countByProductId(Long productId);
    long countByCategoryId(Long categoryId);

    /** Lignes de premier niveau : les composants d'un menu en sont exclus, sinon la
        quantite du ticket compterait deux fois le meme article. */
    List<OrderLine> findByOrderIdAndParentLineIsNullOrderBySortOrderAsc(Long orderId);
}
