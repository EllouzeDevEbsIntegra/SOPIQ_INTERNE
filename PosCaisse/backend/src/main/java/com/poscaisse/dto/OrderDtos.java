package com.poscaisse.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

public final class OrderDtos {
    private OrderDtos() {}

    public record CartLineRequest(@NotNull Long productId, @NotNull BigDecimal quantity, BigDecimal unitPrice,
                                  BigDecimal discountPercent, BigDecimal discountAmount, String note,
                                  List<Long> modifierIds, List<CartLineRequest> components) {}

    public record PaymentRequest(@NotNull Long paymentMethodId, @NotNull BigDecimal amount, BigDecimal tendered, String reference) {}

    public record CartRequest(String clientRef, @NotNull Long registerId, String serviceMode, Long customerId, String customerName,
                              String customerPhone, Long courierId, String note, BigDecimal discountPercent, BigDecimal discountAmount,
                              @NotEmpty List<@Valid CartLineRequest> lines, Long heldOrderId) {}

    public record CheckoutRequest(@NotBlank String clientRef, @NotNull Long registerId, String serviceMode, Long customerId,
                                  String customerName, String customerPhone, Long courierId, String note, BigDecimal discountPercent,
                                  BigDecimal discountAmount, @NotEmpty List<@Valid CartLineRequest> lines,
                                  @NotEmpty List<@Valid PaymentRequest> payments, Long heldOrderId) {}

    public record LineModifierDto(Long modifierId, String name, BigDecimal priceDelta, int quantity) {}
    public record OrderLineDto(Long id, Long productId, String productCode, String productName, Long categoryId, BigDecimal quantity,
                               BigDecimal originalUnitPrice, BigDecimal unitPrice, BigDecimal modifiersTotal, BigDecimal discountPercent,
                               BigDecimal discountAmount, BigDecimal taxRate, BigDecimal lineTotal, String note,
                               List<LineModifierDto> modifiers, List<OrderLineDto> components) {}
    public record PaymentDto(Long id, Long paymentMethodId, String methodCode, String methodName, BigDecimal amount, BigDecimal tendered, BigDecimal changeGiven, String reference, OffsetDateTime createdAt) {}
    public record RefundDto(Long id, Long orderId, String ticketNumber, BigDecimal amount, String reason, String methodName, String userName, OffsetDateTime createdAt, String kind) {}

    public record OrderDto(Long id, String clientRef, String ticketNumber, String heldRef, String status, String serviceMode,
                           Long pointOfSaleId, String pointOfSaleName, Long registerId, String registerCode, Long sessionId,
                           Long cashierId, String cashierName, Long customerId, String customerName, String customerPhone,
                           Long courierId, String courierName, String note,
                           BigDecimal subtotal, BigDecimal lineDiscountTotal, BigDecimal discountPercent, BigDecimal discountAmount,
                           BigDecimal taxTotal, BigDecimal total, BigDecimal paidTotal, BigDecimal changeAmount, BigDecimal refundedTotal,
                           String cancelReason, OffsetDateTime createdAt, OffsetDateTime paidAt, OffsetDateTime cancelledAt,
                           List<OrderLineDto> lines, List<PaymentDto> payments, List<RefundDto> refunds, List<PrintJobDto> printJobs) {}

    public record OrderSummaryDto(Long id, String ticketNumber, String heldRef, String status, String serviceMode, String registerCode,
                                  String cashierName, String customerName, String courierName, BigDecimal total, BigDecimal refundedTotal,
                                  String paymentSummary, OffsetDateTime createdAt, OffsetDateTime paidAt, int itemCount) {}

    public record PrintJobDto(Long id, Long orderId, Long destinationId, String destinationCode, String title, int copies, String content,
                              String status, boolean duplicate, OffsetDateTime createdAt) {}

    public record CancelRequest(@NotBlank String reason, Long refundMethodId) {}
    public record RefundRequest(@NotNull BigDecimal amount, @NotBlank String reason, @NotNull Long paymentMethodId) {}
    public record PageDto<T>(List<T> content, long total, int page, int size) {}
    public record PriceQuote(BigDecimal subtotal, BigDecimal lineDiscountTotal, BigDecimal discountAmount, BigDecimal taxTotal, BigDecimal total, List<OrderLineDto> lines) {}
}
