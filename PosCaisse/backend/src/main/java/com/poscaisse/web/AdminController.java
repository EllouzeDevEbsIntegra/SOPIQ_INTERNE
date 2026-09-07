package com.poscaisse.web;

import com.poscaisse.dto.AdminDtos.*;
import com.poscaisse.dto.OrderDtos.OrderDto;
import com.poscaisse.dto.StockDtos.StockCounterDto;
import com.poscaisse.printing.PrintService;
import com.poscaisse.service.AdminService;
import com.poscaisse.service.OrderService;
import com.poscaisse.service.SettingsService;
import com.poscaisse.service.TicketNumberingAdminService;
import com.poscaisse.service.VariantStockService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

@RestController @RequestMapping("/api") @RequiredArgsConstructor
public class AdminController {
    private final AdminService admin;
    private final SettingsService settings;
    private final PrintService print;
    private final OrderService orders;
    private final TicketNumberingAdminService numbering;
    private final VariantStockService stock;

    // users & roles
    @PreAuthorize("hasAuthority('USERS_MANAGE')") @GetMapping("/users") public List<UserDto> users() { return admin.users(); }
    @PreAuthorize("hasAuthority('USERS_MANAGE')") @PostMapping("/users") public UserDto createUser(@Valid @RequestBody UserRequest r) { return admin.saveUser(null, r); }
    @PreAuthorize("hasAuthority('USERS_MANAGE')") @PutMapping("/users/{id}") public UserDto updateUser(@PathVariable Long id, @Valid @RequestBody UserRequest r) { return admin.saveUser(id, r); }
    @PreAuthorize("hasAuthority('USERS_MANAGE')") @DeleteMapping("/users/{id}") public Map<String, Boolean> deleteUser(@PathVariable Long id) { admin.deleteUser(id); return Map.of("ok", true); }
    @PreAuthorize("hasAuthority('USERS_MANAGE')") @GetMapping("/roles") public List<RoleDto> roles() { return admin.roles(); }
    @PreAuthorize("hasAuthority('USERS_MANAGE')") @PostMapping("/roles") public RoleDto createRole(@Valid @RequestBody RoleRequest r) { return admin.saveRole(null, r); }
    @PreAuthorize("hasAuthority('USERS_MANAGE')") @PutMapping("/roles/{id}") public RoleDto updateRole(@PathVariable Long id, @Valid @RequestBody RoleRequest r) { return admin.saveRole(id, r); }
    @PreAuthorize("hasAuthority('USERS_MANAGE')") @DeleteMapping("/roles/{id}") public Map<String, Boolean> deleteRole(@PathVariable Long id) { admin.deleteRole(id); return Map.of("ok", true); }
    @PreAuthorize("hasAuthority('USERS_MANAGE')") @GetMapping("/permissions") public List<String> permissions() { return admin.permissions(); }

    // company / pos / registers
    @GetMapping("/settings/company") public CompanyDto company() { return admin.company(); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PutMapping("/settings/company") public CompanyDto saveCompany(@Valid @RequestBody CompanyRequest r) { return admin.saveCompany(r); }
    @GetMapping("/points-of-sale") public List<PointOfSaleDto> pos() { return admin.pointsOfSale(); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PostMapping("/points-of-sale") public PointOfSaleDto createPos(@Valid @RequestBody PointOfSaleRequest r) { return admin.savePos(null, r); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PutMapping("/points-of-sale/{id}") public PointOfSaleDto updatePos(@PathVariable Long id, @Valid @RequestBody PointOfSaleRequest r) { return admin.savePos(id, r); }
    @GetMapping("/registers") public List<RegisterDto> registers() { return admin.registers(); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PostMapping("/registers") public RegisterDto createRegister(@Valid @RequestBody RegisterRequest r) { return admin.saveRegister(null, r); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PutMapping("/registers/{id}") public RegisterDto updateRegister(@PathVariable Long id, @Valid @RequestBody RegisterRequest r) { return admin.saveRegister(id, r); }

    // print destinations & receipt templates
    @GetMapping("/print-destinations") public List<PrintDestinationDto> destinations() { return admin.destinations(); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PostMapping("/print-destinations") public PrintDestinationDto createDest(@Valid @RequestBody PrintDestinationRequest r) { return admin.saveDestination(null, r); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PutMapping("/print-destinations/{id}") public PrintDestinationDto updateDest(@PathVariable Long id, @Valid @RequestBody PrintDestinationRequest r) { return admin.saveDestination(id, r); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @DeleteMapping("/print-destinations/{id}") public Map<String, Boolean> deleteDest(@PathVariable Long id) { admin.deleteDestination(id); return Map.of("ok", true); }
    @GetMapping("/receipts/templates") public List<ReceiptTemplateDto> templates() { return print.templates(); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PutMapping("/receipts/templates/{code}") public ReceiptTemplateDto saveTemplate(@PathVariable String code, @RequestBody ReceiptTemplateRequest r) { return print.saveTemplate(code, r); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PostMapping("/receipts/preview") public Map<String, Object> preview(@RequestBody ReceiptTemplateRequest r) { return orders.receiptPreview(r); }
    @GetMapping("/receipts/active") public ReceiptTemplateDto activeTemplate() { return print.dto(print.activeTemplate()); }

    // settings
    @GetMapping("/settings") public Map<String, String> settings() { return settings.all(); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PutMapping("/settings") public Map<String, String> saveSettings(@RequestBody Map<String, String> values) { return settings.update(values); }

    // numerotation des tickets : le format, la portee du compteur, et les compteurs eux-memes
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @GetMapping("/ticket-numbering") public TicketNumberingDto ticketNumbering() { return numbering.etat(); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PostMapping("/ticket-numbering/preview") public TicketNumberingDto previewNumbering(@RequestBody TicketNumberingRequest r) { return numbering.simuler(r); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PutMapping("/ticket-numbering") public TicketNumberingDto saveNumbering(@RequestBody TicketNumberingRequest r) { return numbering.enregistrer(r); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PutMapping("/ticket-numbering/counter") public TicketNumberingDto setCounter(@Valid @RequestBody TicketCounterRequest r) { return numbering.poserCompteur(r.scopeKey(), r.nextValue()); }

    // customers
    @GetMapping("/customers") public List<CustomerDto> customers(@RequestParam(required = false) String q) { return admin.customers(q); }
    @PostMapping("/customers") public CustomerDto createCustomer(@Valid @RequestBody CustomerRequest r) { return admin.saveCustomer(null, r); }
    @PutMapping("/customers/{id}") public CustomerDto updateCustomer(@PathVariable Long id, @Valid @RequestBody CustomerRequest r) { return admin.saveCustomer(id, r); }

    // livreurs
    @GetMapping("/couriers") public List<CourierDto> couriers(@RequestParam(required = false) String q, @RequestParam(defaultValue = "false") boolean activeOnly) { return admin.couriers(q, activeOnly); }
    @PostMapping("/couriers") public CourierDto createCourier(@Valid @RequestBody CourierRequest r) { return admin.saveCourier(null, r); }
    @PutMapping("/couriers/{id}") public CourierDto updateCourier(@PathVariable Long id, @Valid @RequestBody CourierRequest r) { return admin.saveCourier(id, r); }

    // remarques de cuisine
    @GetMapping("/kitchen-notes") public List<KitchenNoteDto> kitchenNotes() { return admin.kitchenNotes(); }
    @PostMapping("/kitchen-notes") public KitchenNoteDto createKitchenNote(@Valid @RequestBody KitchenNoteRequest r) { return admin.saveKitchenNote(null, r); }
    @PutMapping("/kitchen-notes/{id}") public KitchenNoteDto updateKitchenNote(@PathVariable Long id, @Valid @RequestBody KitchenNoteRequest r) { return admin.saveKitchenNote(id, r); }
    @DeleteMapping("/kitchen-notes/{id}") public Map<String, Boolean> deleteKitchenNote(@PathVariable Long id) { admin.deleteKitchenNote(id); return Map.of("ok", true); }
    @PostMapping("/kitchen-notes/reorder") public Map<String, Boolean> reorderKitchenNotes(@RequestBody Map<String, List<Long>> body) { admin.reorderKitchenNotes(body.get("ids")); return Map.of("ok", true); }

    // ingredients
    @GetMapping("/ingredients") public List<IngredientDto> ingredients() { return admin.ingredients(); }
    @PostMapping("/ingredients") public IngredientDto createIngredient(@Valid @RequestBody IngredientRequest r) { return admin.saveIngredient(null, r); }
    @PutMapping("/ingredients/{id}") public IngredientDto updateIngredient(@PathVariable Long id, @Valid @RequestBody IngredientRequest r) { return admin.saveIngredient(id, r); }
    @DeleteMapping("/ingredients/{id}") public Map<String, Boolean> deleteIngredient(@PathVariable Long id) { admin.deleteIngredient(id); return Map.of("ok", true); }
    @PostMapping("/ingredients/reorder") public Map<String, Boolean> reorderIngredients(@RequestBody Map<String, List<Long>> body) { admin.reorderIngredients(body.get("ids")); return Map.of("ok", true); }

    // variantes
    @GetMapping("/variants") public List<VariantDto> variants() { return admin.variants(); }
    @PostMapping("/variants") public VariantDto createVariant(@Valid @RequestBody VariantRequest r) { return admin.saveVariant(null, r); }
    @PutMapping("/variants/{id}") public VariantDto updateVariant(@PathVariable Long id, @Valid @RequestBody VariantRequest r) { return admin.saveVariant(id, r); }
    @DeleteMapping("/variants/{id}") public Map<String, Boolean> deleteVariant(@PathVariable Long id) { admin.deleteVariant(id); return Map.of("ok", true); }
    /*
        Ce qu'il reste des pates, vu du back-office : le gerant regle le suivi ici, il doit
        pouvoir verifier d'ici que le compteur existe et ou il en est. La SAISIE, elle,
        reste en caisse - c'est la que la pate arrive, et le journal de caisse doit la voir
        passer.
    */
    @GetMapping("/variants/stock") public List<StockCounterDto> variantStock() { return stock.compteurs(); }
    @PostMapping("/variants/reorder") public Map<String, Boolean> reorderVariants(@RequestBody Map<String, List<Long>> body) { admin.reorderVariants(body.get("ids")); return Map.of("ok", true); }

    // audit
    @PreAuthorize("hasAuthority('AUDIT_VIEW')")
    @GetMapping("/audit")
    public List<AuditDto> audit(@RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
                                @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to,
                                @RequestParam(required = false) String action, @RequestParam(required = false) Long userId,
                                @RequestParam(defaultValue = "300") int limit) { return admin.auditLogs(from, to, action, userId, limit); }
}
