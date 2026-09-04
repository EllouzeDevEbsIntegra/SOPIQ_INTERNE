package com.poscaisse.repository;

import com.poscaisse.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

@Repository
public interface PaymentRepo extends JpaRepository<Payment, Long> {
    List<Payment> findBySessionId(Long sessionId);

    /* Les valeurs d'énumération sont passées en paramètres plutôt qu'écrites en
       littéraux JPQL : la syntaxe d'un littéral sur une énumération imbriquée
       varie d'une version d'Hibernate à l'autre, le paramètre est sûr. */

    /** Dette portée au compte d'un client : ses paiements à crédit, tickets annulés exclus. */
    @Query("""
            select coalesce(sum(p.amount), 0) from Payment p
             where p.order.customer.id = :partyId
               and p.order.courier is null
               and p.paymentMethod.kind = :kind
               and p.order.status <> :cancelled""")
    BigDecimal creditTotalCustomer(Long partyId, Enums.PaymentKind kind, Enums.OrderStatus cancelled);

    /** Dette portée au compte d'un livreur : les tickets en livraison qui lui sont confiés. */
    @Query("""
            select coalesce(sum(p.amount), 0) from Payment p
             where p.order.courier.id = :partyId
               and p.paymentMethod.kind = :kind
               and p.order.status <> :cancelled""")
    BigDecimal creditTotalCourier(Long partyId, Enums.PaymentKind kind, Enums.OrderStatus cancelled);

    /* Un ticket confié à un livreur est porté à son compte, pas à celui du client :
       c'est le livreur qui détient l'argent jusqu'au versement. La clause
       « courier is null » côté client évite donc de compter la dette deux fois. */

    @Query("""
            select p.order.customer.id as partyId, sum(p.amount) as total from Payment p
             where p.order.customer is not null
               and p.order.courier is null
               and p.paymentMethod.kind = :kind
               and p.order.status <> :cancelled
             group by p.order.customer.id""")
    List<PartyTotal> creditPerCustomer(Enums.PaymentKind kind, Enums.OrderStatus cancelled);

    @Query("""
            select p.order.courier.id as partyId, sum(p.amount) as total from Payment p
             where p.order.courier is not null
               and p.paymentMethod.kind = :kind
               and p.order.status <> :cancelled
             group by p.order.courier.id""")
    List<PartyTotal> creditPerCourier(Enums.PaymentKind kind, Enums.OrderStatus cancelled);

    /** Tickets portés au compte d'un client, du plus récent au plus ancien. */
    @Query("""
            select distinct p.order from Payment p
             where p.order.customer.id = :partyId
               and p.order.courier is null
               and p.paymentMethod.kind = :kind
               and p.order.status <> :cancelled
               and p.order.createdAt between :from and :to
             order by p.order.createdAt desc""")
    List<SaleOrder> creditOrdersCustomer(Long partyId, Enums.PaymentKind kind, Enums.OrderStatus cancelled,
                                         OffsetDateTime from, OffsetDateTime to);

    /** Tickets confiés à un livreur, du plus récent au plus ancien. */
    @Query("""
            select distinct p.order from Payment p
             where p.order.courier.id = :partyId
               and p.paymentMethod.kind = :kind
               and p.order.status <> :cancelled
               and p.order.createdAt between :from and :to
             order by p.order.createdAt desc""")
    List<SaleOrder> creditOrdersCourier(Long partyId, Enums.PaymentKind kind, Enums.OrderStatus cancelled,
                                        OffsetDateTime from, OffsetDateTime to);

    /** Projection : identifiant du titulaire et total, sans charger les entités. */
    interface PartyTotal {
        Long getPartyId();
        BigDecimal getTotal();
    }
}
