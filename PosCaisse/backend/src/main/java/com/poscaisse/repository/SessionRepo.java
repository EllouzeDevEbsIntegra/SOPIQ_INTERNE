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
public interface SessionRepo extends JpaRepository<RegisterSession, Long>, JpaSpecificationExecutor<RegisterSession> {
    Optional<RegisterSession> findFirstByRegisterIdAndStatus(Long registerId, Enums.SessionStatus status);
    List<RegisterSession> findByStatusOrderByOpenedAtDesc(Enums.SessionStatus status);
    Optional<RegisterSession> findFirstByOpenedByIdAndStatusOrderByOpenedAtDesc(Long userId, Enums.SessionStatus status);
    List<RegisterSession> findByRegisterPointOfSaleIdAndOpenedAtBetween(Long posId, OffsetDateTime from, OffsetDateTime to);
}
