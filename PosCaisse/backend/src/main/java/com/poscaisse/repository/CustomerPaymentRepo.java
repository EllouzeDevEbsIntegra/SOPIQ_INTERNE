package com.poscaisse.repository;

import com.poscaisse.domain.CustomerPayment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

@Repository
public interface CustomerPaymentRepo extends JpaRepository<CustomerPayment, Long> {
    List<CustomerPayment> findByCustomerIdOrderByPaidAtDesc(Long customerId);

    List<CustomerPayment> findByCustomerIdAndPaidAtBetweenOrderByPaidAtDesc(Long customerId, OffsetDateTime from, OffsetDateTime to);

    @Query("select coalesce(sum(p.amount), 0) from CustomerPayment p where p.customer.id = :id")
    BigDecimal totalPaid(Long id);

    /** Total réglé par client, en une requête : un appel par client ferait N+1 sur la liste des soldes. */
    @Query("select p.customer.id as customerId, sum(p.amount) as total from CustomerPayment p group by p.customer.id")
    List<PaymentRepo.CustomerTotal> totalPaidByCustomer();
}
