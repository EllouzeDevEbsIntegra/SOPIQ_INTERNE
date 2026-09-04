package com.poscaisse.web;

import com.poscaisse.dto.CatalogDtos.*;
import com.poscaisse.dto.CatalogImportDtos.CatalogImport;
import com.poscaisse.dto.CatalogImportDtos.ImportResult;
import com.poscaisse.dto.CatalogPurgeDtos.PurgeResult;
import com.poscaisse.service.CatalogImportService;
import com.poscaisse.service.CatalogPurgeService;
import com.poscaisse.service.CatalogService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController @RequestMapping("/api") @RequiredArgsConstructor
@PreAuthorize("hasAuthority('PRODUCTS_MANAGE')")
public class CatalogController {
    private final CatalogService catalog;
    private final CatalogImportService catalogImport;
    private final CatalogPurgeService catalogPurge;

    /** Import d'une carte complète. replace=true désactive ce qui n'y figure plus (jamais de suppression). */
    @PostMapping("/catalog/import")
    public ImportResult importCatalog(@RequestBody CatalogImport payload,
                                      @RequestParam(defaultValue = "false") boolean replace) {
        return catalogImport.importCatalog(payload, replace);
    }

    /**
     * Supprime définitivement le catalogue inactif laissé par un import en mode « remplacer ».
     * resetSales=true efface d'abord toutes les données de vente : c'est la seule façon de
     * supprimer un produit déjà vendu. Irréversible, réservé à la mise en production.
     * force=true supprime aussi les sessions de caisse ouvertes, que la vérification refuse
     * par défaut ; à n'envoyer qu'après confirmation explicite de l'utilisateur.
     */
    @PostMapping("/catalog/purge")
    public PurgeResult purgeCatalog(@RequestParam(defaultValue = "false") boolean resetSales,
                                    @RequestParam(defaultValue = "false") boolean force) {
        return catalogPurge.purge(resetSales, force);
    }

    @GetMapping("/categories") public List<CategoryDto> categories() { return catalog.categories(); }
    @PostMapping("/categories") public CategoryDto createCategory(@Valid @RequestBody CategoryRequest r) { return catalog.saveCategory(null, r); }
    @PutMapping("/categories/{id}") public CategoryDto updateCategory(@PathVariable Long id, @Valid @RequestBody CategoryRequest r) { return catalog.saveCategory(id, r); }
    @DeleteMapping("/categories/{id}") public Map<String, Boolean> deleteCategory(@PathVariable Long id) { catalog.deleteCategory(id); return Map.of("ok", true); }
    @PostMapping("/categories/reorder") public Map<String, Boolean> reorderCategories(@RequestBody ReorderRequest r) { catalog.reorderCategories(r.ids()); return Map.of("ok", true); }

    @GetMapping("/products") public List<ProductDto> products() { return catalog.products(); }
    @GetMapping("/products/{id}") public ProductDto product(@PathVariable Long id) { return catalog.product(id); }
    @PostMapping("/products") public ProductDto createProduct(@Valid @RequestBody ProductRequest r) { return catalog.saveProduct(null, r); }
    @PutMapping("/products/{id}") public ProductDto updateProduct(@PathVariable Long id, @Valid @RequestBody ProductRequest r) { return catalog.saveProduct(id, r); }
    @DeleteMapping("/products/{id}") public Map<String, Boolean> deleteProduct(@PathVariable Long id) { catalog.deleteProduct(id); return Map.of("ok", true); }
    @PatchMapping("/products/{id}/availability") public ProductDto availability(@PathVariable Long id, @Valid @RequestBody AvailabilityRequest r) { return catalog.setAvailability(id, r.available()); }
    @PostMapping("/products/reorder") public Map<String, Boolean> reorderProducts(@RequestBody ReorderRequest r) { catalog.reorderProducts(r.ids()); return Map.of("ok", true); }
    @PutMapping("/products/favorites") public Map<String, Boolean> favorites(@RequestBody FavoritesRequest r) { catalog.setFavorites(r.productIds()); return Map.of("ok", true); }

    @GetMapping("/modifiers") public List<ModifierGroupDto> groups() { return catalog.modifierGroups(); }
    @PostMapping("/modifiers") public ModifierGroupDto createGroup(@Valid @RequestBody ModifierGroupRequest r) { return catalog.saveModifierGroup(null, r); }
    @PutMapping("/modifiers/{id}") public ModifierGroupDto updateGroup(@PathVariable Long id, @Valid @RequestBody ModifierGroupRequest r) { return catalog.saveModifierGroup(id, r); }
    @DeleteMapping("/modifiers/{id}") public Map<String, Boolean> deleteGroup(@PathVariable Long id) { catalog.deleteModifierGroup(id); return Map.of("ok", true); }

    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @GetMapping("/payment-methods") public List<PaymentMethodDto> methods() { return catalog.paymentMethods(); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PostMapping("/payment-methods") public PaymentMethodDto createMethod(@Valid @RequestBody PaymentMethodRequest r) { return catalog.savePaymentMethod(null, r); }
    @PreAuthorize("hasAuthority('SETTINGS_MANAGE')") @PutMapping("/payment-methods/{id}") public PaymentMethodDto updateMethod(@PathVariable Long id, @Valid @RequestBody PaymentMethodRequest r) { return catalog.savePaymentMethod(id, r); }
}
