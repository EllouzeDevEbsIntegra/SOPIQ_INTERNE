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
public interface RegisterRepo extends JpaRepository<Register, Long> {
    List<Register> findAllByOrderByCodeAsc();
    List<Register> findByPointOfSaleIdOrderByCodeAsc(Long posId);
}
