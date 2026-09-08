package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.*;
import com.poscaisse.dto.CatalogImportDtos.*;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.*;

/**
 * Import d'une carte complète (catégories, groupes d'options, produits).
 *
 * Les éléments sont rapprochés par nom (catégories, groupes) et par code (produits) :
 * un ré-import met à jour l'existant au lieu de créer des doublons.
 * En mode « remplacer », ce qui n'est pas dans le fichier est **désactivé et non supprimé** :
 * un produit déjà vendu doit rester lié à ses lignes de vente.
 */
@Service @RequiredArgsConstructor @Slf4j
public class CatalogImportService {
    private final CategoryRepo categoryRepo;
    private final ProductRepo productRepo;
    private final ModifierGroupRepo groupRepo;
    private final PrintDestinationRepo destinationRepo;
    private final IngredientRepo ingredientRepo;
    private final VariantRepo variantRepo;
    private final OrderLineRepo orderLineRepo;
    private final OrderLineModifierRepo orderLineModifierRepo;
    private final AuditService audit;

    @Transactional
    public ImportResult importCatalog(CatalogImport payload, boolean replace) {
        if (payload == null || payload.products() == null || payload.products().isEmpty())
            throw new BusinessException("Le fichier de carte ne contient aucun produit.");

        List<String> warnings = new ArrayList<>();
        int catCreated = 0, catUpdated = 0, grpCreated = 0, grpUpdated = 0, prodCreated = 0, prodUpdated = 0;
        int ingCreated = 0, varCreated = 0, aVerifier = 0;

        /*
            INGREDIENTS ET VARIANTES AVANT LES PRODUITS : un article y renvoie par NOM.

            Les deux sont rapproches par nom, jamais crees en double : ré-importer la meme
            carte deux fois ne doit pas donner deux « Thon », sans quoi le filtre en caisse
            en manquerait la moitie. Une valeur d'axe deja vendue garde son identifiant -
            les tickets de l'annee derniere y renvoient.
        */
        Map<String, Ingredient> ingredients = new HashMap<>();
        ingredientRepo.findAll().forEach(i -> ingredients.put(key(i.getName()), i));
        if (payload.ingredients() != null) {
            int ordre = 0;
            for (ImportIngredient in : payload.ingredients()) {
                Ingredient e = ingredients.get(key(in.name()));
                if (e == null) { e = new Ingredient(); e.setName(in.name().trim()); ingCreated++; }
                if (in.shortName() != null && !in.shortName().isBlank()) e.setShortName(in.shortName().trim());
                e.setSortOrder(++ordre);
                e.setActive(true);
                ingredients.put(key(in.name()), ingredientRepo.save(e));
            }
        }

        Map<String, Variant> variants = new HashMap<>();
        Map<String, Map<String, VariantValue>> variantValues = new HashMap<>();
        variantRepo.findAll().forEach(v -> variants.put(key(v.getName()), v));
        if (payload.variants() != null) {
            int ordre = 0;
            for (ImportVariant v : payload.variants()) {
                Variant e = variants.get(key(v.name()));
                if (e == null) { e = new Variant(); e.setName(v.name().trim()); varCreated++; }
                if (v.namePosition() != null)
                    e.setNamePosition(Enums.NamePosition.valueOf(v.namePosition().trim().toUpperCase()));
                e.setSortOrder(++ordre);
                e.setActive(true);
                Map<String, VariantValue> existantes = new HashMap<>();
                e.getValues().forEach(x -> existantes.put(key(x.getName()), x));
                List<VariantValue> suite = new ArrayList<>();
                int i = 0;
                for (ImportVariantValue val : Optional.ofNullable(v.values()).orElse(List.of())) {
                    VariantValue x = existantes.getOrDefault(key(val.name()), new VariantValue());
                    x.setVariant(e);
                    x.setName(val.name().trim());
                    x.setShortName(val.shortName() == null || val.shortName().isBlank() ? null : val.shortName().trim());
                    x.setSortOrder(i++);
                    x.setActive(true);
                    suite.add(x);
                }
                /*
                    Les valeurs absentes du fichier ne sont jamais SUPPRIMEES - les tickets
                    deja imprimes y renvoient - mais elles sont eteintes. Sans cela, la
                    valeur << Cereales >> du jeu de depart resterait a cote de la
                    << Cereale >> du client : deux fois la meme pate dans le choix, dont
                    une grisee a jamais faute de prix.

                    Une valeur qui sert encore de defaut a un article reste allumee : la
                    fermer rendrait cet article invendable d'un appui court, ce que les
                    controles de la fiche interdisent deja.
                */
                for (VariantValue x : e.getValues()) {
                    if (suite.stream().anyMatch(y -> key(y.getName()).equals(key(x.getName())))) continue;
                    boolean sertDeDefaut = x.getId() != null && !variantRepo.produitsAyantPourDefaut(x.getId()).isEmpty();
                    if (!sertDeDefaut) x.setActive(false);
                    else warnings.add("Valeur << " + x.getName() + " >> gardee active : elle est la valeur par defaut d'articles conserves.");
                    suite.add(x);
                }
                e.getValues().clear();
                e.getValues().addAll(suite);
                e = variantRepo.save(e);
                variants.put(key(e.getName()), e);
                Map<String, VariantValue> parNom = new HashMap<>();
                e.getValues().forEach(x -> parNom.put(key(x.getName()), x));
                variantValues.put(key(e.getName()), parNom);
            }
        }
        for (Variant v : variants.values())
            variantValues.computeIfAbsent(key(v.getName()), k -> {
                Map<String, VariantValue> m = new HashMap<>();
                v.getValues().forEach(x -> m.put(key(x.getName()), x));
                return m;
            });

        // ---- groupes d'options ----
        Map<String, ModifierGroup> groups = new HashMap<>();
        groupRepo.findAll().forEach(g -> groups.put(key(g.getName()), g));
        if (payload.modifierGroups() != null) {
            int order = 0;
            for (ImportModifierGroup g : payload.modifierGroups()) {
                ModifierGroup entity = groups.get(key(g.name()));
                boolean isNew = entity == null;
                if (isNew) { entity = new ModifierGroup(); entity.setName(g.name().trim()); }
                entity.setRequired(Boolean.TRUE.equals(g.required()));
                entity.setMultiple(Boolean.TRUE.equals(g.multiple()));
                entity.setMinSelect(g.minSelect() == null ? (entity.isRequired() ? 1 : 0) : g.minSelect());
                entity.setMaxSelect(g.maxSelect() == null ? (entity.isMultiple() ? 0 : 1) : g.maxSelect());
                entity.setSortOrder(order++);
                entity.setActive(true);
                // les options existantes sont conservées quand le nom correspond : les ventes passées gardent leur référence
                Map<String, Modifier> existing = new HashMap<>();
                entity.getModifiers().forEach(m -> existing.put(key(m.getName()), m));
                List<Modifier> next = new ArrayList<>();
                int i = 0;
                for (ImportModifier m : Optional.ofNullable(g.modifiers()).orElse(List.of())) {
                    Modifier mod = existing.getOrDefault(key(m.name()), new Modifier());
                    mod.setGroup(entity);
                    mod.setName(m.name().trim());
                    mod.setPriceDelta(Money.r(m.priceDelta()));
                    mod.setSortOrder(i++);
                    mod.setActive(true);
                    next.add(mod);
                }
                entity.getModifiers().clear();
                entity.getModifiers().addAll(next);
                entity = groupRepo.save(entity);
                groups.put(key(entity.getName()), entity);
                if (isNew) grpCreated++; else grpUpdated++;
            }
        }

        // ---- catégories ----
        Map<String, Category> categories = new HashMap<>();
        categoryRepo.findAll().forEach(c -> categories.put(key(c.getName()), c));
        Set<String> importedCategories = new HashSet<>();
        if (payload.categories() != null) {
            int order = 0;
            for (ImportCategory c : payload.categories()) {
                Category entity = categories.get(key(c.name()));
                boolean isNew = entity == null;
                if (isNew) { entity = new Category(); entity.setName(c.name().trim()); }
                if (c.color() != null) entity.setColor(c.color());
                entity.setIcon(c.icon());
                entity.setSortOrder(c.sortOrder() == null ? ++order : c.sortOrder());
                entity.setActive(true);
                if (c.printDestination() != null) {
                    destinationRepo.findByCode(c.printDestination().toUpperCase()).ifPresentOrElse(
                            entity::setPrintDestination,
                            () -> warnings.add("Destination d'impression inconnue : " + c.printDestination()));
                }
                entity = categoryRepo.save(entity);
                categories.put(key(entity.getName()), entity);
                importedCategories.add(key(entity.getName()));
                if (isNew) catCreated++; else catUpdated++;
            }
        }

        // ---- produits ----
        Map<String, Product> products = new HashMap<>();
        productRepo.findAll().forEach(p -> products.put(key(p.getCode()), p));
        Set<String> importedCodes = new HashSet<>();
        int order = 0;
        for (ImportProduct p : payload.products()) {
            Category category = categories.get(key(p.category()));
            if (category == null) { warnings.add("Produit « " + p.name() + " » ignoré : catégorie « " + p.category() + " » inconnue."); continue; }
            Product entity = products.get(key(p.code()));
            boolean isNew = entity == null;
            if (isNew) { entity = new Product(); entity.setCode(p.code().trim()); }
            entity.setName(p.name().trim());
            entity.setShortName(p.shortName() == null || p.shortName().isBlank() ? null : p.shortName().trim());
            entity.setDescription(p.description());
            entity.setCategory(category);
            entity.setProductType(Enums.ProductType.SIMPLE);
            entity.setPrice(Money.r(p.price()));
            entity.setTaxRate(p.taxRate() == null ? BigDecimal.ZERO : p.taxRate());
            entity.setColor(p.color() != null ? p.color() : category.getColor());
            entity.setSortOrder(p.sortOrder() == null ? ++order : p.sortOrder());
            entity.setActive(true);
            entity.setAvailable(true);
            entity.setFavorite(Boolean.TRUE.equals(p.favorite()));
            entity.setFavoriteOrder(p.favoriteOrder() == null ? 0 : p.favoriteOrder());
            entity.setPriceToCheck(Boolean.TRUE.equals(p.priceToCheck()));
            if (entity.isPriceToCheck()) aVerifier++;
            /*
                Le code-barres, quand la carte en porte un.
                Un doublon n'est pas une raison de refuser toute la carte : on garde le
                premier, on signale le second, et l'import continue - une carte de trois
                cents lignes ne doit pas s'arreter sur une coquille de saisie.
            */
            String cb = p.barcode() == null || p.barcode().isBlank() ? null : p.barcode().trim();
            if (cb != null) {
                Product deja = productRepo.findByBarcode(cb).orElse(null);
                if (deja != null && (isNew || !deja.getId().equals(entity.getId()))) {
                    warnings.add("Code-barres déjà utilisé par « " + deja.getName() + " » : "
                            + cb + " — « " + p.name() + " » est importé sans code.");
                    cb = null;
                }
            }
            entity.setBarcode(cb);
            if (p.purchasePrice() != null) entity.setPurchasePrice(Money.r(p.purchasePrice()));
            entity.setStockManaged(Boolean.TRUE.equals(p.stockManaged()));
            if (p.stockMin() != null) entity.setStockMin(Money.r(p.stockMin()));
            // Une unite illisible n'arrete pas l'import de 187 articles : l'article reste
            // a la piece, et l'avertissement dit lequel et pourquoi.
            if (p.unite() != null && !p.unite().isBlank()) {
                try { entity.setUnite(Enums.Unite.valueOf(p.unite().trim().toUpperCase())); }
                catch (IllegalArgumentException e) {
                    warnings.add("« " + p.name() + " » : unité « " + p.unite() + " » inconnue, article laissé à la pièce.");
                }
            }
            entity.setUpdatedAt(OffsetDateTime.now());

            entity.getPrintDestinations().clear();
            if (p.printDestinations() != null)
                for (String d : p.printDestinations())
                    destinationRepo.findByCode(d.toUpperCase()).ifPresentOrElse(entity.getPrintDestinations()::add,
                            () -> warnings.add("Destination d'impression inconnue : " + d));

            entity.getModifierGroups().clear();
            if (p.modifierGroups() != null) {
                int i = 0;
                for (String gName : p.modifierGroups()) {
                    ModifierGroup g = groups.get(key(gName));
                    if (g == null) { warnings.add("Groupe d'options inconnu pour « " + p.name() + " » : " + gName); continue; }
                    ProductModifierGroup link = new ProductModifierGroup();
                    link.setProduct(entity); link.setModifierGroup(g); link.setSortOrder(i++);
                    entity.getModifierGroups().add(link);
                }
            }
            entity.getIngredients().clear();
            if (p.ingredients() != null)
                for (String nom : p.ingredients()) {
                    Ingredient in = ingredients.get(key(nom));
                    if (in == null) { warnings.add("Ingredient inconnu pour « " + p.name() + " » : " + nom); continue; }
                    if (!entity.getIngredients().contains(in)) entity.getIngredients().add(in);
                }

            /*
                La variante en dernier, et d'un bloc : l'axe, les prix, puis le defaut.
                L'ordre compte - le defaut est refuse s'il n'a pas de prix, et son prix
                vient d'etre pose. C'est le meme controle qu'a l'ecran : un article a
                variante doit rester vendable d'un seul appui.
            */
            entity.getVariantPrices().clear();
            entity.setVariant(null);
            entity.setDefaultVariantValue(null);
            entity.setAskVariant(false);
            if (p.variant() != null && !p.variant().isBlank()) {
                Variant axe = variants.get(key(p.variant()));
                Map<String, VariantValue> valeurs = variantValues.getOrDefault(key(p.variant()), Map.of());
                if (axe == null) warnings.add("Variante inconnue pour « " + p.name() + " » : " + p.variant());
                else {
                    entity.setVariant(axe);
                    entity.setAskVariant(Boolean.TRUE.equals(p.askVariant()));
                    for (ImportVariantPrice vp : Optional.ofNullable(p.variantPrices()).orElse(List.of())) {
                        VariantValue val = valeurs.get(key(vp.value()));
                        if (val == null) { warnings.add("Valeur inconnue de « " + axe.getName() + " » pour « " + p.name() + " » : " + vp.value()); continue; }
                        ProductVariantPrice ligne = new ProductVariantPrice();
                        ligne.setProduct(entity); ligne.setValue(val); ligne.setPrice(Money.r(vp.price()));
                        entity.getVariantPrices().add(ligne);
                    }
                    VariantValue defaut = p.defaultVariantValue() == null ? null : valeurs.get(key(p.defaultVariantValue()));
                    if (defaut == null)
                        warnings.add("« " + p.name() + " » : valeur par defaut manquante, la variante n'est pas posee.");
                    else if (entity.getVariantPrices().stream().noneMatch(x -> x.getValue().getId().equals(defaut.getId()) && x.getPrice().signum() > 0))
                        warnings.add("« " + p.name() + " » : la valeur par defaut « " + defaut.getName() + " » n'a pas de prix, la variante n'est pas posee.");
                    else { entity.setDefaultVariantValue(defaut); }
                    if (entity.getDefaultVariantValue() == null) { entity.setVariant(null); entity.getVariantPrices().clear(); entity.setAskVariant(false); }
                }
            }

            entity = productRepo.save(entity);
            products.put(key(entity.getCode()), entity);
            importedCodes.add(key(entity.getCode()));
            if (isNew) prodCreated++; else prodUpdated++;
        }

        // ---- ce qui n'est plus à la carte : supprimé s'il n'a jamais servi, désactivé sinon ----
        int prodOff = 0, catOff = 0, prodDeleted = 0;
        if (replace) {
            // les menus d'abord : leurs composants référencent les produits simples
            List<Product> obsolete = productRepo.findAll().stream()
                    .filter(p -> !importedCodes.contains(key(p.getCode())))
                    .sorted(Comparator.comparing(p -> p.getProductType() == Enums.ProductType.MENU ? 0 : 1))
                    .toList();
            for (Product p : obsolete) {
                if (orderLineRepo.countByProductId(p.getId()) == 0) {
                    productRepo.delete(p);
                    productRepo.flush();
                    prodDeleted++;
                } else if (p.isActive()) {
                    p.setActive(false); p.setFavorite(false); p.setUpdatedAt(OffsetDateTime.now());
                    productRepo.save(p); prodOff++;
                }
            }
            for (ModifierGroup g : groupRepo.findAll()) {
                if (payload.modifierGroups() != null && payload.modifierGroups().stream().anyMatch(x -> key(x.name()).equals(key(g.getName())))) continue;
                if (orderLineModifierRepo.countByModifier_Group_Id(g.getId()) == 0) { groupRepo.delete(g); groupRepo.flush(); }
                else if (g.isActive()) { g.setActive(false); groupRepo.save(g); }
            }
            for (Category c : categoryRepo.findAll()) {
                if (importedCategories.contains(key(c.getName()))) continue;
                if (productRepo.countByCategoryId(c.getId()) == 0 && orderLineRepo.countByCategoryId(c.getId()) == 0) {
                    categoryRepo.delete(c);
                    categoryRepo.flush();
                } else if (c.isActive()) { c.setActive(false); categoryRepo.save(c); catOff++; }
            }
        }

        productRepo.flush();
        String label = payload.label() == null ? "carte" : payload.label();
        if (prodDeleted > 0) warnings.add(prodDeleted + " ancien(s) produit(s) supprimé(s) ; " + prodOff + " conservé(s) mais désactivé(s) car déjà vendu(s).");
        audit.log("CATALOG_IMPORT", "Catalog", null, label + " : " + prodCreated + " créés, " + prodUpdated
                + " mis à jour, " + prodDeleted + " supprimés, " + prodOff + " désactivés" + (replace ? " (mode remplacement)" : ""));
        log.info("Import de carte « {} » : {} produits créés, {} mis à jour, {} supprimés, {} désactivés",
                label, prodCreated, prodUpdated, prodDeleted, prodOff);
        return new ImportResult(label, catCreated, catUpdated, grpCreated, grpUpdated, prodCreated, prodUpdated, prodOff, catOff,
                ingCreated, varCreated, aVerifier, warnings);
    }

    private static String key(String s) { return s == null ? "" : s.trim().toLowerCase(); }
}
