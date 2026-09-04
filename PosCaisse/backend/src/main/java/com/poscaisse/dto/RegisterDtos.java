package com.poscaisse.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

public final class RegisterDtos {
    private RegisterDtos() {}

    public record OpenSessionRequest(@NotNull Long registerId, @NotNull BigDecimal openingFloat) {}
    public record CloseSessionRequest(@NotNull BigDecimal countedCash, String note) {}
    public record CashMovementRequest(@NotBlank String type, @NotBlank String reason, @NotNull BigDecimal amount, String comment) {}

    public record SessionDto(Long id, Long registerId, String registerCode, String registerName, Long pointOfSaleId, String pointOfSaleName,
                             String status, OffsetDateTime openedAt, OffsetDateTime closedAt, Long openedById, String openedByName,
                             Long closedById, String closedByName, BigDecimal openingFloat, BigDecimal cashSales, BigDecimal cardSales,
                             BigDecimal otherSales, BigDecimal cashRefunds, BigDecimal cashIn, BigDecimal cashOut, BigDecimal expectedCash,
                             BigDecimal countedCash, BigDecimal cashDifference, Integer ticketsCount, BigDecimal revenue, String closingNote) {}

    public record SessionSummary(Long sessionId, BigDecimal openingFloat, BigDecimal cashSales, BigDecimal cardSales, BigDecimal otherSales,
                                 BigDecimal cashRefunds, BigDecimal otherRefunds, BigDecimal cashIn, BigDecimal cashOut, BigDecimal expectedCash,
                                 int ticketsCount, int cancellationsCount, BigDecimal revenue, BigDecimal discounts,
                                 Map<String, BigDecimal> byMethod) {}

    public record CashMovementDto(Long id, Long sessionId, String type, String reason, BigDecimal amount, String comment, String userName, OffsetDateTime createdAt) {}

    public record JournalDto(Long id, Long pointOfSaleId, String pointOfSaleName, Long registerId, String registerCode, Long sessionId,
                             Long userId, String userName, String eventType, BigDecimal amount, String reference, String description, OffsetDateTime createdAt) {}

    public record RegisterStatusDto(Long id, String code, String name, Long pointOfSaleId, String pointOfSaleName, boolean active,
                                    SessionDto openSession) {}

    public record DailyClosureRequest(@NotNull Long pointOfSaleId, @NotNull LocalDate businessDate, String note) {}
    public record DailyClosureDto(Long id, Long pointOfSaleId, String pointOfSaleName, LocalDate businessDate, String closedByName,
                                  OffsetDateTime closedAt, BigDecimal revenue, int ticketsCount, BigDecimal averageTicket, BigDecimal cashTotal,
                                  BigDecimal cardTotal, BigDecimal otherTotal, BigDecimal discountsTotal, int cancellationsCount,
                                  BigDecimal cancellationsTotal, BigDecimal refundsTotal, BigDecimal cashIn, BigDecimal cashOut,
                                  BigDecimal cashDifference, String note, Object details) {}
    public record DailyPreview(LocalDate businessDate, Long pointOfSaleId, BigDecimal revenue, int ticketsCount, BigDecimal averageTicket,
                               BigDecimal cashTotal, BigDecimal cardTotal, BigDecimal otherTotal, BigDecimal discountsTotal,
                               int cancellationsCount, BigDecimal cancellationsTotal, BigDecimal refundsTotal, BigDecimal cashIn,
                               BigDecimal cashOut, BigDecimal cashDifference, List<Map<String, Object>> byRegister,
                               List<Map<String, Object>> byCashier, List<Map<String, Object>> byMethod, List<SessionDto> sessions,
                               boolean alreadyClosed, int openSessions) {}
}
