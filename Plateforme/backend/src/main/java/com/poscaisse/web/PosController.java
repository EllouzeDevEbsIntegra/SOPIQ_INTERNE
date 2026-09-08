package com.poscaisse.web;

import com.poscaisse.dto.CatalogDtos.CatalogResponse;
import com.poscaisse.dto.CatalogDtos.ProductDto;
import com.poscaisse.dto.OrderDtos.*;
import com.poscaisse.dto.RegisterDtos.*;
import com.poscaisse.dto.StockDtos.*;
import com.poscaisse.printing.PrintService;
import com.poscaisse.service.CatalogService;
import com.poscaisse.service.OrderService;
import com.poscaisse.service.RegisterSessionService;
import com.poscaisse.service.ProductStockService;
import com.poscaisse.service.VariantStockService;
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
    private final VariantStockService stock;
    private final ProductStockService stockArticles;

    @GetMapping("/catalog") public CatalogResponse catalog() { return catalog.posCatalog(); }

    @PreAuthorize("hasAuthority('SELL')")
    @PatchMapping("/products/{id}/availability")
    public ProductDto availability(@PathVariable Long id, @RequestBody Map<String, Boolean> body) { return catalog.setAvailability(id, Boolean.TRUE.equals(body.get("available"))); }

    @GetMapping("/registers") public List<RegisterStatusDto> registers(@RequestParam(required = false) Long posId) { return sessions.registers(posId); }
    @GetMapping("/session") public SessionDto currentSession() { return sessions.current(); }
    @PostMapping("/session/open") public SessionDto open(@Valid @RequestBody OpenSessionRequest req) { return sessions.open(req); }
    @GetMapping("/session/{id}/summary") public SessionSummary summary(@PathVariable Long id) { return sessions.summary(id); }
    @PostMapping("/session/{id}/close") public SessionDto close(@PathVariable Long id, @Valid @RequestBody CloseSessionRequest req) { return sessions.close(id, req); }
    /** L'etat de caisse a imprimer : rendu par le serveur, comme un ticket. */
    @GetMapping("/session/{id}/report") public SessionReport report(@PathVariable Long id) { return sessions.report(id); }
    @GetMapping("/session/{id}/movements") public List<CashMovementDto> movements(@PathVariable Long id) { return sessions.movements(id); }
    @PostMapping("/session/{id}/movements") public CashMovementDto movement(@PathVariable Long id, @Valid @RequestBody CashMovementRequest req) { return sessions.addMovement(id, req); }

    /*
        Le stock des pates. Le point de vente n'est pas demande : c'est celui de la caisse
        ouverte par le caissier. Le lui faire choisir serait lui offrir de tenir le stock
        d'un autre restaurant.
    */
    @GetMapping("/stock") public StockStateDto stock() { return stock.etat(sessions.currentPointOfSale()); }
    @PostMapping("/stock/entry") public StockStateDto stockEntry(@Valid @RequestBody StockMoveRequest req) { return stock.entrer(sessions.currentPointOfSale(), req); }
    @PostMapping("/stock/waste") public StockStateDto stockWaste(@Valid @RequestBody StockMoveRequest req) { return stock.casser(sessions.currentPointOfSale(), req); }

    /*
        Le stock des ARTICLES - celui de la boutique. Meme regle que pour les pates : le
        point de vente est celui de la caisse ouverte, jamais un choix offert au caissier.

        L'inventaire pose le chiffre compte au lieu d'un ecart : devant son rayon, le
        gerant lit ce qu'il voit, il ne fait pas de soustraction.
    */
    @GetMapping("/article-stock") public ProductStockStateDto articleStock() { return stockArticles.etat(sessions.currentPointOfSale()); }
    @GetMapping("/article-stock/{productId}/history") public List<ProductStockMovementDto> articleStockHistory(@PathVariable Long productId) { return stockArticles.historique(productId); }
    @PostMapping("/article-stock/entry") public ProductStockStateDto articleStockEntry(@Valid @RequestBody ProductStockMoveRequest req) { return stockArticles.entrer(sessions.currentPointOfSale(), req); }
    @PostMapping("/article-stock/waste") public ProductStockStateDto articleStockWaste(@Valid @RequestBody ProductStockMoveRequest req) { return stockArticles.casser(sessions.currentPointOfSale(), req); }
    @PostMapping("/article-stock/count") public ProductStockStateDto articleStockCount(@Valid @RequestBody ProductStockMoveRequest req) { return stockArticles.inventaire(sessions.currentPointOfSale(), req); }

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
