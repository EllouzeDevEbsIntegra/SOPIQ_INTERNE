package com.poscaisse.web;

import com.poscaisse.dto.OrderDtos.*;
import com.poscaisse.printing.PrintService;
import com.poscaisse.service.OrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

@RestController @RequestMapping("/api/orders") @RequiredArgsConstructor
public class OrderController {
    private final OrderService orders;
    private final PrintService print;

    @PreAuthorize("hasAuthority('TICKETS_VIEW')")
    @GetMapping
    public PageDto<OrderSummaryDto> search(@RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
                                           @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to,
                                           @RequestParam(required = false) String status, @RequestParam(required = false) Long registerId,
                                           @RequestParam(required = false) Long cashierId, @RequestParam(required = false) Long posId,
                                           @RequestParam(required = false) String ticket, @RequestParam(required = false) BigDecimal minAmount,
                                           @RequestParam(required = false) BigDecimal maxAmount, @RequestParam(required = false) String method,
                                           @RequestParam(required = false) Long sessionId,
                                           @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "50") int size) {
        return orders.search(from, to, status, registerId, cashierId, posId, ticket, minAmount, maxAmount, method, sessionId, page, size);
    }

    @PreAuthorize("hasAuthority('TICKETS_VIEW')") @GetMapping("/{id}") public OrderDto get(@PathVariable Long id) { return orders.get(id); }
    @PreAuthorize("hasAuthority('TICKETS_VIEW')") @GetMapping("/by-ticket/{ticket}") public OrderDto byTicket(@PathVariable String ticket) { return orders.byTicket(ticket); }
    @PreAuthorize("hasAuthority('TICKETS_VIEW')") @GetMapping("/{id}/print-jobs") public List<PrintJobDto> jobs(@PathVariable Long id) { return print.jobsForOrder(id); }
    @PostMapping("/{id}/reprint") public List<PrintJobDto> reprint(@PathVariable Long id) { return orders.reprint(id); }
    @PostMapping("/{id}/cancel") public OrderDto cancel(@PathVariable Long id, @Valid @RequestBody CancelRequest req) { return orders.cancel(id, req); }
    @PostMapping("/{id}/refund") public OrderDto refund(@PathVariable Long id, @Valid @RequestBody RefundRequest req) { return orders.refund(id, req); }
}
