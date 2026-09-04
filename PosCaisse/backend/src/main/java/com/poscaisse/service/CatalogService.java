package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.*;
import com.poscaisse.dto.AdminDtos;
import com.poscaisse.dto.CatalogDtos.*;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service @RequiredArgsConstructor
public class CatalogService {
    private final CategoryRepo categoryRepo;
    private final ProductRepo productRepo;
    private final ModifierGroupRepo groupRepo;
    private final PrintDestinationRepo destinationRepo;
    private final PaymentMethodRepo paymentMethodRepo;
    private final CompanyRepo companyRepo;
    private final KitchenNoteRepo kitchenNoteRepo;
    private final SettingsService settings;
    private final AuditService audit;

    // ---------- POS catalog ----------
    @Transactional(readOnly = true)
    public CatalogResponse posCatalog() {
        Map<Long, Long> counts = productRepo.findAll().stream().filter(Product::isActive)
                .collect(Collectors.groupingBy(p -> p.getCategory().getId(), Collectors.counting()));
        List<CategoryDto> cats = categoryRepo.findAllByOrderBySortOrderAscIdAsc().stream().filter(Category::isActive)
                .map(c -> Mappers.category(c, counts.getOrDefault(c.getId(), 0L))).toList();
        List<ProductDto> products = productRepo.findByActiveTrueOrderBySortOrderAscNameAsc().stream()
                .filter(p -> p.getCategory().isActive()).map(Mappers::product).toList();
        List<PaymentMethodDto> methods = paymentMethodRepo.findAllByOrderBySortOrderAscIdAsc().stream().filter(PaymentMethod::isActive).map(Mappers::paymentMethod).toList();
        Company c = companyRepo.findAll().stream().findFirst().orElse(null);
        CompanyInfo info = c == null ? null : new CompanyInfo(c.getName(), c.getTradeName(), c.getCurrency(), c.getCurrencySymbol(), c.getDecimals(), c.getLogoData());
        // Les remarques de cuisine voyagent avec le catalogue : la boite de dialogue
        // de la caisse doit pouvoir les proposer sans aller-retour supplementaire.
        List<AdminDtos.KitchenNoteDto> notes = kitchenNoteRepo.findByActiveTrueOrderBySortOrderAscIdAsc()
                .stream().map(Mappers::kitchenNote).toList();
        return new CatalogResponse(cats, products, methods, settings.all(), info, notes);
    }

    // ---------- Categories ----------
    @Transactional(readOnly = true)
    public List<CategoryDto> categories() {
        return categoryRepo.findAllByOrderBySortOrderAscIdAsc().stream().map(c -> Mappers.category(c, productRepo.countByCategoryId(c.getId()))).toList();
    }

    @Transactional
    public CategoryDto saveCategory(Long id, CategoryRequest r) {
        Category c = id == null ? new Category() : categoryRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Catégorie"));
        c.setName(r.name().trim());
        if (r.color() != null) c.setColor(r.color());
        c.setIcon(r.icon());
        if (r.sortOrder() != null) c.setSortOrder(r.sortOrder());
        else if (id == null) c.setSortOrder((int) categoryRepo.count() + 1);
        if (r.active() != null) c.setActive(r.active());
        c.setPrintDestination(r.printDestinationId() == null ? null : destinationRepo.findById(r.printDestinationId()).orElse(null));
        c = categoryRepo.save(c);
        audit.log(id == null ? "CATEGORY_CREATE" : "CATEGORY_UPDATE", "Category", c.getId(), c.getName());
        return Mappers.category(c, productRepo.countByCategoryId(c.getId()));
    }

    @Transactional
    public void deleteCategory(Long id) {
        if (productRepo.countByCategoryId(id) > 0) throw new BusinessException("Impossible de supprimer : cette catégorie contient des produits. Désactivez-la plutôt.");
        categoryRepo.deleteById(id);
        audit.log("CATEGORY_DELETE", "Category", id, null);
    }

    @Transactional
    public void reorderCategories(List<Long> ids) {
        int i = 0;
        for (Long id : ids) { Category c = categoryRepo.findById(id).orElse(null); if (c != null) { c.setSortOrder(++i); categoryRepo.save(c); } }
    }

    // ---------- Products ----------
    @Transactional(readOnly = true)
    public List<ProductDto> products() { return productRepo.findAllByOrderBySortOrderAscNameAsc().stream().map(Mappers::product).toList(); }

    @Transactional(readOnly = true)
    public ProductDto product(Long id) { return Mappers.product(productRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Produit"))); }

    @Transactional
    public ProductDto saveProduct(Long id, ProductRequest r) {
        Product p = id == null ? new Product() : productRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Produit"));
        productRepo.findByCode(r.code().trim()).filter(o -> !o.getId().equals(p.getId())).ifPresent(o -> { throw BusinessException.conflict("Le code produit « " + r.code() + " » existe déjà."); });
        if (r.price().signum() < 0) throw new BusinessException("Le prix ne peut pas être négatif.");
        p.setCode(r.code().trim());
        p.setReference(r.reference());
        p.setName(r.name().trim());
        p.setShortName(r.shortName() == null || r.shortName().isBlank() ? null : r.shortName().trim());
        p.setDescription(r.description());
        p.setCategory(categoryRepo.findById(r.categoryId()).orElseThrow(() -> BusinessException.notFound("Catégorie")));
        p.setProductType(r.productType() == null ? Enums.ProductType.SIMPLE : Enums.ProductType.valueOf(r.productType()));
        p.setPrice(Money.r(r.price()));
        p.setTaxRate(r.taxRate() == null ? BigDecimal.ZERO : r.taxRate());
        p.setImageUrl(r.imageUrl());
        p.setColor(r.color());
        if (r.sortOrder() != null) p.setSortOrder(r.sortOrder());
        if (r.active() != null) p.setActive(r.active());
        if (r.available() != null) p.setAvailable(r.available());
        if (r.favorite() != null) p.setFavorite(r.favorite());
        if (r.favoriteOrder() != null) p.setFavoriteOrder(r.favoriteOrder());
        p.setUpdatedAt(OffsetDateTime.now());
        p.getPrintDestinations().clear();
        if (r.printDestinationIds() != null) r.printDestinationIds().forEach(d -> destinationRepo.findById(d).ifPresent(p.getPrintDestinations()::add));
        p.getModifierGroups().clear();
        if (r.modifierGroupIds() != null) {
            int i = 0;
            for (Long gid : r.modifierGroupIds()) {
                ModifierGroup g = groupRepo.findById(gid).orElseThrow(() -> BusinessException.notFound("Groupe d'options"));
                ProductModifierGroup pmg = new ProductModifierGroup();
                pmg.setProduct(p); pmg.setModifierGroup(g); pmg.setSortOrder(i++);
                p.getModifierGroups().add(pmg);
            }
        }
        p.getMenuComponents().clear();
        if (p.getProductType() == Enums.ProductType.MENU && r.menuComponents() != null) {
            int i = 0;
            for (MenuComponentRequest cr : r.menuComponents()) {
                MenuComponent mc = new MenuComponent();
                mc.setMenuProduct(p); mc.setName(cr.name()); mc.setQuantity(cr.quantity() == null ? 1 : Math.max(1, cr.quantity()));
                mc.setSortOrder(cr.sortOrder() == null ? i : cr.sortOrder()); i++;
                if (cr.options() != null) for (MenuOptionRequest o : cr.options()) {
                    Product op = productRepo.findById(o.productId()).orElseThrow(() -> BusinessException.notFound("Produit composant"));
                    if (op.getProductType() == Enums.ProductType.MENU) throw new BusinessException("Un menu ne peut pas contenir un autre menu.");
                    MenuComponentProduct mcp = new MenuComponentProduct();
                    mcp.setComponent(mc); mcp.setProduct(op); mcp.setPriceDelta(Money.r(o.priceDelta()));
                    mc.getOptions().add(mcp);
                }
                p.getMenuComponents().add(mc);
            }
        }
        Product saved = productRepo.saveAndFlush(p);
        audit.log(id == null ? "PRODUCT_CREATE" : "PRODUCT_UPDATE", "Product", saved.getId(), saved.getCode() + " " + saved.getName() + " prix=" + saved.getPrice());
        return Mappers.product(saved);
    }

    @Transactional
    public ProductDto setAvailability(Long id, boolean available) {
        Product p = productRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Produit"));
        p.setAvailable(available);
        p.setUpdatedAt(OffsetDateTime.now());
        audit.log(available ? "PRODUCT_AVAILABLE" : "PRODUCT_UNAVAILABLE", "Product", id, p.getName());
        return Mappers.product(productRepo.save(p));
    }

    @Transactional
    public void deleteProduct(Long id) {
        Product p = productRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Produit"));
        try {
            productRepo.delete(p);
            productRepo.flush();
            audit.log("PRODUCT_DELETE", "Product", id, p.getName());
        } catch (org.springframework.dao.DataIntegrityViolationException e) {
            throw new BusinessException("Ce produit a déjà été vendu : il ne peut pas être supprimé. Désactivez-le plutôt.");
        }
    }

    @Transactional
    public void reorderProducts(List<Long> ids) {
        int i = 0;
        for (Long id : ids) { Product p = productRepo.findById(id).orElse(null); if (p != null) { p.setSortOrder(++i); productRepo.save(p); } }
    }

    @Transactional
    public void setFavorites(List<Long> ids) {
        Set<Long> set = new HashSet<>(ids);
        for (Product p : productRepo.findAll()) {
            boolean fav = set.contains(p.getId());
            p.setFavorite(fav);
            p.setFavoriteOrder(fav ? ids.indexOf(p.getId()) : 0);
        }
        audit.log("FAVORITES_UPDATE", "Product", null, ids.toString());
    }

    // ---------- Modifier groups ----------
    @Transactional(readOnly = true)
    public List<ModifierGroupDto> modifierGroups() {
        return groupRepo.findAllByOrderBySortOrderAscIdAsc().stream().map(g -> new ModifierGroupDto(g.getId(), g.getName(), g.isRequired(), g.isMultiple(),
                g.getMinSelect(), g.getMaxSelect(), g.getSortOrder(), g.isActive(), g.getModifiers().stream().map(Mappers::modifier).toList())).toList();
    }

    @Transactional
    public ModifierGroupDto saveModifierGroup(Long id, ModifierGroupRequest r) {
        ModifierGroup g = id == null ? new ModifierGroup() : groupRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Groupe d'options"));
        g.setName(r.name().trim());
        if (r.required() != null) g.setRequired(r.required());
        if (r.multiple() != null) g.setMultiple(r.multiple());
        if (r.minSelect() != null) g.setMinSelect(Math.max(0, r.minSelect()));
        if (r.maxSelect() != null) g.setMaxSelect(Math.max(0, r.maxSelect()));
        if (r.sortOrder() != null) g.setSortOrder(r.sortOrder());
        if (r.active() != null) g.setActive(r.active());
        if (!g.isMultiple()) { g.setMaxSelect(1); }
        if (g.isRequired() && g.getMinSelect() == 0) g.setMinSelect(1);
        if (r.modifiers() != null) {
            Map<Long, Modifier> existing = g.getModifiers().stream().filter(m -> m.getId() != null).collect(Collectors.toMap(Modifier::getId, m -> m));
            List<Modifier> next = new ArrayList<>();
            int i = 0;
            for (ModifierRequest mr : r.modifiers()) {
                Modifier m = mr.id() != null && existing.containsKey(mr.id()) ? existing.get(mr.id()) : new Modifier();
                m.setGroup(g); m.setName(mr.name().trim()); m.setPriceDelta(Money.r(mr.priceDelta()));
                m.setSortOrder(mr.sortOrder() == null ? i : mr.sortOrder()); i++;
                if (mr.active() != null) m.setActive(mr.active());
                next.add(m);
            }
            g.getModifiers().clear();
            g.getModifiers().addAll(next);
        }
        g = groupRepo.saveAndFlush(g);
        audit.log(id == null ? "MODIFIER_GROUP_CREATE" : "MODIFIER_GROUP_UPDATE", "ModifierGroup", g.getId(), g.getName());
        return Mappers.modifierGroup(g);
    }

    @Transactional
    public void deleteModifierGroup(Long id) {
        try { groupRepo.deleteById(id); groupRepo.flush(); }
        catch (org.springframework.dao.DataIntegrityViolationException e) { throw new BusinessException("Ce groupe est utilisé par des ventes : désactivez-le plutôt."); }
        audit.log("MODIFIER_GROUP_DELETE", "ModifierGroup", id, null);
    }

    // ---------- Payment methods ----------
    @Transactional(readOnly = true)
    public List<PaymentMethodDto> paymentMethods() { return paymentMethodRepo.findAllByOrderBySortOrderAscIdAsc().stream().map(Mappers::paymentMethod).toList(); }

    @Transactional
    public PaymentMethodDto savePaymentMethod(Long id, PaymentMethodRequest r) {
        PaymentMethod m = id == null ? new PaymentMethod() : paymentMethodRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Moyen de paiement"));
        paymentMethodRepo.findByCode(r.code().trim().toUpperCase()).filter(o -> !o.getId().equals(m.getId())).ifPresent(o -> { throw BusinessException.conflict("Ce code existe déjà."); });
        m.setCode(r.code().trim().toUpperCase()); m.setName(r.name().trim()); m.setKind(Enums.PaymentKind.valueOf(r.kind()));
        if (r.opensDrawer() != null) m.setOpensDrawer(r.opensDrawer());
        if (r.sortOrder() != null) m.setSortOrder(r.sortOrder());
        if (r.active() != null) m.setActive(r.active());
        audit.log("PAYMENT_METHOD_SAVE", "PaymentMethod", m.getId(), m.getCode());
        return Mappers.paymentMethod(paymentMethodRepo.save(m));
    }
}
