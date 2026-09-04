package com.poscaisse.web;

import com.poscaisse.dto.CatalogDtos.CatalogResponse;
import com.poscaisse.dto.CatalogDtos.ProductDto;
import com.poscaisse.dto.OrderDtos.*;
import com.poscaisse.dto.RegisterDtos.*;
import com.poscaisse.printing.PrintService;
import com.poscaisse.service.CatalogService;
import com.poscaisse.service.OrderService;
import com.poscaisse.service.RegisterSessionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** Endpoints used by the touch POS screen. */
@RestController @RequestMapping("/api/pos") @RequiredArgsConstructor
public class PosController {
    private final CatalogService catalog;
    private final OrderService orders;
    private final RegisterSessionService sessions;
    private final PrintService print;

    @GetMapping("/catalog") public CatalogResponse catalog() { return catalog.posCatalog(); }

    @PreAuthorize("hasAuthority('SELL')")
    @PatchMapping("/products/{id}/availability")
    public ProductDto availability(@PathVariable Long id, @RequestBody Map<String, Boolean> body) { return catalog.setAvailability(id, Boolean.TRUE.equals(body.get("available"))); }

    @GetMapping("/registers") public List<RegisterStatusDto> registers(@RequestParam(required = false) Long posId) { return sessions.registers(posId); }
    @GetMapping("/session") public SessionDto currentSession() { return sessions.current(); }
    @PostMapping("/session/open") public SessionDto open(@Valid @RequestBody OpenSessionRequest req) { return sessions.open(req); }
    @GetMapping("/session/{id}/summary") public SessionSummary summary(@PathVariable Long id) { return sessions.summary(id); }
    @PostMapping("/session/{id}/close") public SessionDto close(@PathVariable Long id, @Valid @RequestBody CloseSessionRequest req) { return sessions.close(id, req); }
    @GetMapping("/session/{id}/movements") public List<CashMovementDto> movements(@PathVariable Long id) { return sessions.movements(id); }
    @PostMapping("/session/{id}/movements") public CashMovementDto movement(@PathVariable Long id, @Valid @RequestBody CashMovementRequest req) { return sessions.addMovement(id, req); }

    @PostMapping("/quote") public PriceQuote quote(@Valid @RequestBody CartRequest req) { return orders.quote(req); }
    @PostMapping("/checkout") public OrderDto checkout(@Valid @RequestBody CheckoutRequest req) { return orders.checkout(req); }
    @PostMapping("/hold") public OrderDto hold(@Valid @RequestBody CartRequest req) { return orders.hold(req); }
    @GetMapping("/held") public List<OrderDto> held(@RequestParam(required = false) Long posId) { return orders.heldOrders(posId); }
    @DeleteMapping("/held/{id}") public Map<String, Boolean> abandon(@PathVariable Long id) { orders.abandonHeld(id); return Map.of("ok", true); }

    @GetMapping("/print-jobs/pending") public List<PrintJobDto> pending() { return print.pending(); }
    @PostMapping("/print-jobs/ack") public Map<String, Boolean> ack(@RequestBody Map<String, Object> body) {
        @SuppressWarnings("unchecked") List<Integer> ids = (List<Integer>) body.getOrDefault("ids", List.of());
        print.markPrinted(ids.stream().map(Integer::longValue).toList(), Boolean.TRUE.equals(body.get("failed")));
        return Map.of("ok", true);
    }
}
