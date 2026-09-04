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
public interface SequenceRepo extends JpaRepository<DocumentSequence, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from DocumentSequence s where s.scopeKey = :key")
    Optional<DocumentSequence> lockByKey(@Param("key") String key);
}
