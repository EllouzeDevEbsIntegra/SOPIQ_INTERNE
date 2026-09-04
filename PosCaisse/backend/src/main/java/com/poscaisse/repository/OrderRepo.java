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
public interface OrderRepo extends JpaRepository<SaleOrder, Long>, JpaSpecificationExecutor<SaleOrder> {
    Optional<SaleOrder> findByClientRef(String clientRef);
    Optional<SaleOrder> findByTicketNumber(String ticketNumber);
    List<SaleOrder> findByStatusAndRegisterPointOfSaleIdOrderByCreatedAtAsc(Enums.OrderStatus status, Long posId);
    List<SaleOrder> findByStatusOrderByCreatedAtAsc(Enums.OrderStatus status);
    List<SaleOrder> findBySessionIdOrderByPaidAtDesc(Long sessionId);
    long countBySessionIdAndStatusIn(Long sessionId, List<Enums.OrderStatus> statuses);
}
