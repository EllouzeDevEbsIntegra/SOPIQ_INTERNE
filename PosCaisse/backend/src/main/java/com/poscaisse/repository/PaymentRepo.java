package com.poscaisse.repository;

import com.poscaisse.domain.*;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface PaymentRepo extends JpaRepository<Payment, Long> {
    List<Payment> findBySessionId(Long sessionId);

    /* Les valeurs d'énumération sont passées en paramètres plutôt qu'écrites en
       littéraux JPQL : la syntaxe d'un littéral sur une énumération imbriquée
       varie d'une version d'Hibernate à l'autre, le paramètre est sûr. */

    /** Dette portée au compte d'un client : ses paiements à crédit, tickets annulés exclus. */
    @Query("""
            select coalesce(sum(p.amount), 0) from Payment p
             where p.order.customer.id = :customerId
               and p.paymentMethod.kind = :kind
               and p.order.status <> :cancelled""")
    BigDecimal creditTotal(Long customerId, Enums.PaymentKind kind, Enums.OrderStatus cancelled);

    /** Dette de tous les clients en une seule requête : un appel par client ferait N+1. */
    @Query("""
            select p.order.customer.id as customerId, sum(p.amount) as total from Payment p
             where p.order.customer is not null
               and p.paymentMethod.kind = :kind
               and p.order.status <> :cancelled
             group by p.order.customer.id""")
    List<CustomerTotal> creditTotals(Enums.PaymentKind kind, Enums.OrderStatus cancelled);

    /** Tickets portés au compte d'un client, du plus récent au plus ancien. */
    @Query("""
            select distinct p.order from Payment p
             where p.order.customer.id = :customerId
               and p.paymentMethod.kind = :kind
               and p.order.status <> :cancelled
               and p.order.createdAt between :from and :to
             order by p.order.createdAt desc""")
    List<SaleOrder> creditOrders(Long customerId, Enums.PaymentKind kind, Enums.OrderStatus cancelled,
                                 OffsetDateTime from, OffsetDateTime to);

    /** Projection : identifiant du client et total, sans charger les entités. */
    interface CustomerTotal {
        Long getCustomerId();
        BigDecimal getTotal();
    }
}
