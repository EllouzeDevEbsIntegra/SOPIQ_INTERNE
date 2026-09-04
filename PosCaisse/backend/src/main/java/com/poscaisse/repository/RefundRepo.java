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
public interface RefundRepo extends JpaRepository<Refund, Long> {
    List<Refund> findBySessionId(Long sessionId);
    List<Refund> findByOrderIdOrderByCreatedAtAsc(Long orderId);
}
