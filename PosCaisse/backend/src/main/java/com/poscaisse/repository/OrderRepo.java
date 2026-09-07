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

    /**
     * Le plus grand compteur deja imprime sous une FORME donnee : le texte du numero,
     * les chiffres du compteur remplaces par des jokers (PV01-2026-______). C'est
     * exactement l'ensemble des numeros qui pourraient se heurter au prochain, puisque
     * deux numeros ne se heurtent que s'ils s'ecrivent pareil.
     *
     * Sert a placer un compteur qui vient d'etre cree - changement de portee, nouvelle
     * periode - au-dessus de ce qui existe, plutot qu'a 1. Le filtre sur les chiffres
     * ecarte un numero saisi a la main qui ne tiendrait pas dans un entier.
     */
    @Query(value = """
            select coalesce(max(cast(substring(o.ticket_number from :debut for :longueur) as bigint)), 0)
              from sale_order o
             where o.ticket_number like :forme escape '!'
               and substring(o.ticket_number from :debut for :longueur) ~ '^[0-9]+$'
            """, nativeQuery = true)
    long maxSequenceInShape(@Param("forme") String forme, @Param("debut") int debut, @Param("longueur") int longueur);
}
