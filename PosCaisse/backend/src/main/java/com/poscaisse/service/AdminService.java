package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.*;
import com.poscaisse.dto.AdminDtos.*;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.*;
import com.poscaisse.security.CurrentUser;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;

@Service @RequiredArgsConstructor
public class AdminService {
    private final UserRepo userRepo;
    private final RoleRepo roleRepo;
    private final CompanyRepo companyRepo;
    private final PointOfSaleRepo posRepo;
    private final RegisterRepo registerRepo;
    private final PrintDestinationRepo destinationRepo;
    private final CustomerRepo customerRepo;
    private final CourierRepo courierRepo;
    private final KitchenNoteRepo kitchenNoteRepo;
    private final IngredientRepo ingredientRepo;
    private final AuditRepo auditRepo;
    private final SessionRepo sessionRepo;
    private final PasswordEncoder encoder;
    private final CurrentUser currentUser;
    private final AuditService audit;

    // ---------- users ----------
    @Transactional(readOnly = true)
    public List<UserDto> users() { return userRepo.findAllByOrderByFullNameAsc().stream().map(Mappers::user).toList(); }

    @Transactional
    public UserDto saveUser(Long id, UserRequest r) {
        User u = id == null ? new User() : userRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Utilisateur"));
        userRepo.findByUsernameIgnoreCase(r.username().trim()).filter(o -> !o.getId().equals(u.getId())).ifPresent(o -> { throw BusinessException.conflict("Ce nom d'utilisateur existe déjà."); });
        Role role = roleRepo.findById(r.roleId()).orElseThrow(() -> BusinessException.notFound("Rôle"));
        if (id != null && id.equals(currentUser.id()) && !"ADMIN".equals(role.getCode()) && "ADMIN".equals(u.getRole().getCode()))
            throw new BusinessException("Vous ne pouvez pas retirer votre propre rôle administrateur.");
        u.setUsername(r.username().trim()); u.setFullName(r.fullName().trim()); u.setRole(role);
        u.setPointOfSale(r.pointOfSaleId() == null ? null : posRepo.findById(r.pointOfSaleId()).orElse(null));
        u.setMaxDiscountPercent(r.maxDiscountPercent()); u.setColor(r.color());
        if (r.active() != null) {
            if (!r.active() && id != null && id.equals(currentUser.id())) throw new BusinessException("Vous ne pouvez pas désactiver votre propre compte.");
            u.setActive(r.active());
        }
        if (r.password() != null && !r.password().isBlank()) {
            if (r.password().length() < 6) throw new BusinessException("Le mot de passe doit contenir au moins 6 caractères.");
            u.setPasswordHash(encoder.encode(r.password()));
        }
        if (r.pin() != null && !r.pin().isBlank()) { AuthService.validatePin(r.pin()); u.setPinHash(encoder.encode(r.pin())); }
        if (id == null && u.getPinHash() == null && u.getPasswordHash() == null) throw new BusinessException("Définissez au moins un PIN ou un mot de passe.");
        u.setUpdatedAt(OffsetDateTime.now());
        User saved = userRepo.save(u);
        audit.log(id == null ? "USER_CREATE" : "USER_UPDATE", "User", saved.getId(), saved.getUsername() + " rôle=" + role.getCode() + (r.pin() != null && !r.pin().isBlank() ? " PIN modifié" : ""));
        return Mappers.user(saved);
    }

    @Transactional
    public void deleteUser(Long id) {
        if (id.equals(currentUser.id())) throw new BusinessException("Vous ne pouvez pas supprimer votre propre compte.");
        User u = userRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Utilisateur"));
        try { userRepo.delete(u); userRepo.flush(); }
        catch (org.springframework.dao.DataIntegrityViolationException e) { throw new BusinessException("Cet utilisateur a des ventes ou sessions : désactivez-le plutôt."); }
        audit.log("USER_DELETE", "User", id, u.getUsername());
    }

    // ---------- roles ----------
    @Transactional(readOnly = true)
    public List<RoleDto> roles() {
        List<User> users = userRepo.findAll();
        return roleRepo.findAll(Sort.by("id")).stream().map(r -> Mappers.role(r, users.stream().filter(u -> u.getRole().getId().equals(r.getId())).count())).toList();
    }

    @Transactional
    public RoleDto saveRole(Long id, RoleRequest r) {
        Role role = id == null ? new Role() : roleRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Rôle"));
        String code = r.code().trim().toUpperCase().replace(' ', '_');
        roleRepo.findByCode(code).filter(o -> !o.getId().equals(role.getId())).ifPresent(o -> { throw BusinessException.conflict("Ce code de rôle existe déjà."); });
        if (role.isSystemRole() && !role.getCode().equals(code)) throw new BusinessException("Le code d'un rôle système ne peut pas être modifié.");
        role.setCode(code); role.setName(r.name().trim());
        EnumSet<Permission> perms = EnumSet.noneOf(Permission.class);
        if (r.permissions() != null) r.permissions().forEach(p -> { try { perms.add(Permission.valueOf(p)); } catch (IllegalArgumentException e) { throw new BusinessException("Permission inconnue : " + p); } });
        if ("ADMIN".equals(code)) perms.addAll(EnumSet.allOf(Permission.class));
        role.setPermissions(perms);
        Role saved = roleRepo.save(role);
        audit.log(id == null ? "ROLE_CREATE" : "ROLE_UPDATE", "Role", saved.getId(), code + " " + perms);
        return Mappers.role(saved, userRepo.findAll().stream().filter(u -> u.getRole().getId().equals(saved.getId())).count());
    }

    @Transactional
    public void deleteRole(Long id) {
        Role r = roleRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Rôle"));
        if (r.isSystemRole()) throw new BusinessException("Un rôle système ne peut pas être supprimé.");
        if (userRepo.findAll().stream().anyMatch(u -> u.getRole().getId().equals(id))) throw new BusinessException("Des utilisateurs utilisent ce rôle.");
        roleRepo.delete(r);
        audit.log("ROLE_DELETE", "Role", id, r.getCode());
    }

    public List<String> permissions() { return EnumSet.allOf(Permission.class).stream().map(Enum::name).toList(); }

    // ---------- company ----------
    @Transactional(readOnly = true)
    public CompanyDto company() { return Mappers.company(companyRepo.findAll().stream().findFirst().orElseThrow(() -> BusinessException.notFound("Entreprise"))); }

    @Transactional
    public CompanyDto saveCompany(CompanyRequest r) {
        Company c = companyRepo.findAll().stream().findFirst().orElseGet(Company::new);
        c.setName(r.name().trim()); c.setTradeName(r.tradeName()); c.setAddress(r.address()); c.setPhone(r.phone()); c.setTaxId(r.taxId());
        if (r.currency() != null && !r.currency().isBlank()) c.setCurrency(r.currency().trim().toUpperCase());
        if (r.currencySymbol() != null && !r.currencySymbol().isBlank()) c.setCurrencySymbol(r.currencySymbol().trim());
        if (r.decimals() != null) c.setDecimals(Math.max(0, Math.min(3, r.decimals())));
        if (r.timezone() != null && !r.timezone().isBlank()) c.setTimezone(r.timezone());
        if (r.logoData() != null) c.setLogoData(r.logoData().isBlank() ? null : r.logoData());
        c.setUpdatedAt(OffsetDateTime.now());
        audit.log("COMPANY_UPDATE", "Company", c.getId(), c.getName());
        return Mappers.company(companyRepo.save(c));
    }

    // ---------- points of sale / registers ----------
    @Transactional(readOnly = true)
    public List<PointOfSaleDto> pointsOfSale() {
        return posRepo.findAllByOrderByNameAsc().stream().map(p -> Mappers.pos(p, registerRepo.findByPointOfSaleIdOrderByCodeAsc(p.getId()).size())).toList();
    }

    @Transactional
    public PointOfSaleDto savePos(Long id, PointOfSaleRequest r) {
        PointOfSale p = id == null ? new PointOfSale() : posRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Point de vente"));
        posRepo.findByCode(r.code().trim().toUpperCase()).filter(o -> !o.getId().equals(p.getId())).ifPresent(o -> { throw BusinessException.conflict("Ce code de point de vente existe déjà."); });
        if (id == null) p.setCompany(companyRepo.findAll().stream().findFirst().orElseThrow());
        p.setCode(r.code().trim().toUpperCase()); p.setName(r.name().trim()); p.setAddress(r.address()); p.setPhone(r.phone());
        if (r.active() != null) p.setActive(r.active());
        PointOfSale saved = posRepo.save(p);
        audit.log(id == null ? "POS_CREATE" : "POS_UPDATE", "PointOfSale", saved.getId(), saved.getCode());
        return Mappers.pos(saved, registerRepo.findByPointOfSaleIdOrderByCodeAsc(saved.getId()).size());
    }

    @Transactional(readOnly = true)
    public List<RegisterDto> registers() { return registerRepo.findAllByOrderByCodeAsc().stream().map(Mappers::register).toList(); }

    @Transactional
    public RegisterDto saveRegister(Long id, RegisterRequest r) {
        Register reg = id == null ? new Register() : registerRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Caisse"));
        PointOfSale pos = posRepo.findById(r.pointOfSaleId()).orElseThrow(() -> BusinessException.notFound("Point de vente"));
        String code = r.code().trim().toUpperCase();
        registerRepo.findByPointOfSaleIdOrderByCodeAsc(pos.getId()).stream().filter(o -> o.getCode().equalsIgnoreCase(code) && !o.getId().equals(reg.getId())).findAny()
                .ifPresent(o -> { throw BusinessException.conflict("Ce code de caisse existe déjà sur ce point de vente."); });
        if (r.active() != null && !r.active() && id != null && sessionRepo.findFirstByRegisterIdAndStatus(id, Enums.SessionStatus.OPEN).isPresent())
            throw new BusinessException("Impossible de désactiver une caisse avec une session ouverte.");
        reg.setPointOfSale(pos); reg.setCode(code); reg.setName(r.name().trim());
        if (r.active() != null) reg.setActive(r.active());
        Register saved = registerRepo.save(reg);
        audit.log(id == null ? "REGISTER_CREATE" : "REGISTER_UPDATE", "Register", saved.getId(), saved.getCode());
        return Mappers.register(saved);
    }

    // ---------- print destinations ----------
    @Transactional(readOnly = true)
    public List<PrintDestinationDto> destinations() { return destinationRepo.findAllByOrderBySortOrderAscIdAsc().stream().map(Mappers::destination).toList(); }

    @Transactional
    public PrintDestinationDto saveDestination(Long id, PrintDestinationRequest r) {
        PrintDestination d = id == null ? new PrintDestination() : destinationRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Destination"));
        String code = r.code().trim().toUpperCase();
        destinationRepo.findByCode(code).filter(o -> !o.getId().equals(d.getId())).ifPresent(o -> { throw BusinessException.conflict("Ce code de destination existe déjà."); });
        d.setCode(code); d.setName(r.name().trim());
        if (r.kind() != null) d.setKind(Enums.DestinationKind.valueOf(r.kind()));
        if (r.copies() != null) d.setCopies(Math.max(0, Math.min(5, r.copies())));
        if (r.showPrices() != null) d.setShowPrices(r.showPrices());
        if (r.sortOrder() != null) d.setSortOrder(r.sortOrder());
        if (r.active() != null) d.setActive(r.active());
        PrintDestination saved = destinationRepo.save(d);
        audit.log("PRINT_DESTINATION_SAVE", "PrintDestination", saved.getId(), saved.getCode() + " copies=" + saved.getCopies());
        return Mappers.destination(saved);
    }

    @Transactional
    public void deleteDestination(Long id) {
        try { destinationRepo.deleteById(id); destinationRepo.flush(); }
        catch (org.springframework.dao.DataIntegrityViolationException e) { throw new BusinessException("Cette destination est utilisée : désactivez-la plutôt."); }
        audit.log("PRINT_DESTINATION_DELETE", "PrintDestination", id, null);
    }

    // ---------- customers ----------
    @Transactional(readOnly = true)
    public List<CustomerDto> customers(String q) {
        return (q == null || q.isBlank() ? customerRepo.findAllByOrderByNameAsc() : customerRepo.search(q.trim())).stream().limit(200).map(Mappers::customer).toList();
    }

    @Transactional
    public CustomerDto saveCustomer(Long id, CustomerRequest r) {
        Customer c = id == null ? new Customer() : customerRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Client"));
        c.setName(r.name().trim()); c.setPhone(r.phone() == null ? null : r.phone().trim()); c.setNote(r.note());
        return Mappers.customer(customerRepo.save(c));
    }

    // ---------- livreurs ----------
    @Transactional(readOnly = true)
    public List<CourierDto> couriers(String q, boolean activeOnly) {
        List<Courier> all = q == null || q.isBlank() ? courierRepo.findAllByOrderByNameAsc() : courierRepo.search(q.trim());
        return all.stream().filter(c -> !activeOnly || c.isActive()).limit(200).map(Mappers::courier).toList();
    }

    @Transactional
    public CourierDto saveCourier(Long id, CourierRequest r) {
        Courier c = id == null ? new Courier() : courierRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Livreur"));
        c.setName(r.name().trim()); c.setPhone(r.phone() == null ? null : r.phone().trim()); c.setNote(r.note());
        if (r.active() != null) c.setActive(r.active());
        return Mappers.courier(courierRepo.save(c));
    }

    // ---------- remarques de cuisine ----------
    @Transactional(readOnly = true)
    public List<KitchenNoteDto> kitchenNotes() {
        return kitchenNoteRepo.findAllByOrderBySortOrderAscIdAsc().stream().map(Mappers::kitchenNote).toList();
    }

    @Transactional
    public KitchenNoteDto saveKitchenNote(Long id, KitchenNoteRequest r) {
        currentUser.require(Permission.PRODUCTS_MANAGE, "Vous n'avez pas la permission de modifier les remarques de cuisine.");
        KitchenNote n = id == null ? new KitchenNote() : kitchenNoteRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Remarque"));
        // Une nouvelle remarque se range en fin de liste : la placer en tete deplacerait
        // sous les doigts du caissier des touches dont il connait la position.
        if (id == null) n.setSortOrder(kitchenNoteRepo.findAll().stream().mapToInt(KitchenNote::getSortOrder).max().orElse(0) + 1);
        n.setLabel(r.label().trim());
        if (r.sortOrder() != null) n.setSortOrder(r.sortOrder());
        if (r.active() != null) n.setActive(r.active());
        return Mappers.kitchenNote(kitchenNoteRepo.save(n));
    }

    @Transactional
    public void deleteKitchenNote(Long id) {
        currentUser.require(Permission.PRODUCTS_MANAGE, "Vous n'avez pas la permission de supprimer une remarque de cuisine.");
        // Les tickets deja passes gardent leur texte : rien ne les reference, la
        // suppression est donc sans effet sur l'historique.
        kitchenNoteRepo.deleteById(id);
        audit.log("KITCHEN_NOTE_DELETE", "KitchenNote", id, null);
    }

    /** Ordre d'affichage en caisse : la liste recue fait foi. */
    @Transactional
    public void reorderKitchenNotes(List<Long> ids) {
        currentUser.require(Permission.PRODUCTS_MANAGE, "Vous n'avez pas la permission de réordonner les remarques.");
        int i = 0;
        for (Long id : ids) {
            KitchenNote n = kitchenNoteRepo.findById(id).orElse(null);
            if (n != null) { n.setSortOrder(i++); kitchenNoteRepo.save(n); }
        }
    }

    // ---------- ingredients ----------
    @Transactional(readOnly = true)
    public List<IngredientDto> ingredients() {
        return ingredientRepo.findAllByOrderBySortOrderAscIdAsc().stream().map(Mappers::ingredient).toList();
    }

    @Transactional
    public IngredientDto saveIngredient(Long id, IngredientRequest r) {
        currentUser.require(Permission.PRODUCTS_MANAGE, "Vous n'avez pas la permission de modifier les ingrédients.");
        String nom = r.name().trim();
        // Deux « Thon » dans la liste rendraient le filtre de la caisse incomprehensible :
        // l'utilisateur en cocherait un et manquerait les articles portant l'autre.
        ingredientRepo.findByNameIgnoreCase(nom).filter(o -> !o.getId().equals(id))
                .ifPresent(o -> { throw BusinessException.conflict("L'ingrédient « " + nom + " » existe déjà."); });
        Ingredient i = id == null ? new Ingredient() : ingredientRepo.findById(id).orElseThrow(() -> BusinessException.notFound("Ingrédient"));
        // Un nouvel ingredient se range en fin de liste, comme les remarques : les touches
        // deja connues ne bougent pas sous les doigts.
        if (id == null) i.setSortOrder(ingredientRepo.findAll().stream().mapToInt(Ingredient::getSortOrder).max().orElse(0) + 1);
        i.setName(nom);
        if (r.sortOrder() != null) i.setSortOrder(r.sortOrder());
        if (r.active() != null) i.setActive(r.active());
        return Mappers.ingredient(ingredientRepo.save(i));
    }

    @Transactional
    public void deleteIngredient(Long id) {
        currentUser.require(Permission.PRODUCTS_MANAGE, "Vous n'avez pas la permission de supprimer un ingrédient.");
        // Le lien avec les articles tombe avec lui (ON DELETE CASCADE), mais leur NOM
        // garde le mot : il a ete copie a la saisie. Seule la recherche par cet
        // ingredient cesse de les trouver, ce que la confirmation annonce.
        ingredientRepo.deleteById(id);
        audit.log("INGREDIENT_DELETE", "Ingredient", id, null);
    }

    /** Ordre des touches dans la fiche article : la liste recue fait foi. */
    @Transactional
    public void reorderIngredients(List<Long> ids) {
        currentUser.require(Permission.PRODUCTS_MANAGE, "Vous n'avez pas la permission de réordonner les ingrédients.");
        int i = 0;
        for (Long id : ids) {
            Ingredient n = ingredientRepo.findById(id).orElse(null);
            if (n != null) { n.setSortOrder(i++); ingredientRepo.save(n); }
        }
    }

    // ---------- audit ----------
    @Transactional(readOnly = true)
    public List<AuditDto> auditLogs(OffsetDateTime from, OffsetDateTime to, String action, Long userId, int limit) {
        Specification<AuditLog> spec = (root, q, cb) -> {
            List<Predicate> p = new ArrayList<>();
            if (from != null) p.add(cb.greaterThanOrEqualTo(root.get("createdAt"), from));
            if (to != null) p.add(cb.lessThan(root.get("createdAt"), to));
            if (action != null && !action.isBlank()) p.add(cb.like(root.get("action"), "%" + action.toUpperCase() + "%"));
            if (userId != null) p.add(cb.equal(root.get("userId"), userId));
            return cb.and(p.toArray(new Predicate[0]));
        };
        return auditRepo.findAll(spec, PageRequest.of(0, Math.min(Math.max(limit, 1), 2000), Sort.by(Sort.Direction.DESC, "id"))).getContent().stream().map(Mappers::audit).toList();
    }
}
