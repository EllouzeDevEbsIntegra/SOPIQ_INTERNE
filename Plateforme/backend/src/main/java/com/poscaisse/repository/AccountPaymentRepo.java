package com.poscaisse.repository;

import com.poscaisse.domain.AccountPayment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

/** Règlements portés sur les comptes : clients et livreurs partagent la même table. */
@Repository
public interface AccountPaymentRepo extends JpaRepository<AccountPayment, Long> {

    List<AccountPayment> findByCustomerIdAndPaidAtBetweenOrderByPaidAtDesc(Long customerId, OffsetDateTime from, OffsetDateTime to);

    List<AccountPayment> findByCourierIdAndPaidAtBetweenOrderByPaidAtDesc(Long courierId, OffsetDateTime from, OffsetDateTime to);

    @Query("select coalesce(sum(p.amount), 0) from AccountPayment p where p.customer.id = :id")
    BigDecimal totalPaidByCustomer(Long id);

    @Query("select coalesce(sum(p.amount), 0) from AccountPayment p where p.courier.id = :id")
    BigDecimal totalPaidByCourier(Long id);

    /* Un total par titulaire en une requête : un appel par compte ferait N+1 sur la liste des soldes. */

    @Query("select p.customer.id as partyId, sum(p.amount) as total from AccountPayment p where p.customer is not null group by p.customer.id")
    List<PaymentRepo.PartyTotal> paidPerCustomer();

    @Query("select p.courier.id as partyId, sum(p.amount) as total from AccountPayment p where p.courier is not null group by p.courier.id")
    List<PaymentRepo.PartyTotal> paidPerCourier();
}
