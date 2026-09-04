package com.poscaisse.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

/**
 * Comptes clients et comptes livreurs : dette portée par les tickets à crédit, règlements
 * qui la diminuent, et relevé. Les deux natures de compte partagent la même forme, donc
 * les mêmes contrats : « party » désigne le titulaire, client ou livreur.
 */
public final class AccountDtos {
    private AccountDtos() {}

    /**
     * Solde d'un compte. Le solde n'est pas stocké mais recalculé à partir de ses deux
     * mouvements, ce qui interdit toute dérive entre le solde affiché et son détail.
     */
    public record AccountBalanceDto(Long partyId, String name, String phone,
                                    BigDecimal charged, BigDecimal paid, BigDecimal balance) {}

    /** Une ligne « ticket » du relevé : en-tête seulement, le détail se charge au clic. */
    public record StatementTicketDto(Long orderId, String ticketNumber, OffsetDateTime date,
                                     String note, BigDecimal quantity, BigDecimal total) {}

    /** Une ligne « règlement » du relevé. */
    public record StatementPaymentDto(Long id, String number, OffsetDateTime date,
                                      String method, BigDecimal amount, String note, String userName) {}

    public record StatementDto(String party, Long partyId, String name, String phone,
                               BigDecimal totalTickets, BigDecimal totalPayments, BigDecimal balance,
                               List<StatementTicketDto> tickets, List<StatementPaymentDto> payments) {}

    public record AccountPaymentRequest(@NotNull Long partyId, @NotNull Long paymentMethodId,
                                        @NotNull @Positive BigDecimal amount, String note) {}
}
