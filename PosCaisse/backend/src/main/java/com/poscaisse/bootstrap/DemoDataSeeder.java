package com.poscaisse.bootstrap;

import com.poscaisse.config.AppProperties;
import com.poscaisse.domain.*;
import com.poscaisse.printing.ReceiptRenderer;
import com.poscaisse.repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;

/**
 * Seeds a rich, realistic demo dataset on first start (empty database only).
 * Demo accounts: admin / admin123 (PIN 9999), manager / manager123 (PIN 2222), ahmed PIN 1234, sami PIN 5678, mariem PIN 4321.
 */
@Component @RequiredArgsConstructor @Slf4j
public class DemoDataSeeder implements ApplicationRunner {
    private final AppProperties props;
    private final CompanyRepo companyRepo; private final PointOfSaleRepo posRepo; private final RegisterRepo registerRepo;
    private final RoleRepo roleRepo; private final UserRepo userRepo; private final PrintDestinationRepo destRepo;
    private final CategoryRepo categoryRepo; private final ProductRepo productRepo; private final ModifierGroupRepo groupRepo;
    private final PaymentMethodRepo paymentRepo; private final ReceiptTemplateRepo templateRepo; private final CustomerRepo customerRepo;
    private final PasswordEncoder encoder; private final ObjectMapper om;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (roleRepo.count() == 0) seedCore();
        if (props.isDemoData() && companyRepo.count() == 0) seedDemo();
    }

    private void seedCore() {
        role("ADMIN", "Administrateur", EnumSet.allOf(Permission.class));
        role("MANAGER", "Manager", EnumSet.of(Permission.REGISTER_OPEN, Permission.SELL, Permission.DISCOUNT_APPLY, Permission.DISCOUNT_HIGH, Permission.PRICE_EDIT,
                Permission.LINE_DELETE, Permission.ORDER_CANCEL, Permission.TICKET_CANCEL, Permission.REFUND, Permission.DRAWER_OPEN, Permission.REVENUE_VIEW,
                Permission.CASH_MOVEMENT, Permission.REGISTER_CLOSE, Permission.DAILY_CLOSE, Permission.PRODUCTS_MANAGE, Permission.REPORTS_VIEW,
                Permission.TICKETS_VIEW, Permission.TICKETS_REPRINT, Permission.BACKOFFICE_ACCESS, Permission.AUDIT_VIEW));
        role("CASHIER", "Caissier", EnumSet.of(Permission.REGISTER_OPEN, Permission.SELL, Permission.DISCOUNT_APPLY, Permission.LINE_DELETE, Permission.ORDER_CANCEL,
                Permission.DRAWER_OPEN, Permission.CASH_MOVEMENT, Permission.REGISTER_CLOSE, Permission.TICKETS_VIEW, Permission.TICKETS_REPRINT));
        if (paymentRepo.count() == 0) {
            pay("CASH", "Espèces", Enums.PaymentKind.CASH, true, 1); pay("CARD", "Carte bancaire", Enums.PaymentKind.CARD, false, 2);
            pay("CHECK", "Chèque", Enums.PaymentKind.CHECK, false, 3); pay("VOUCHER", "Ticket restaurant", Enums.PaymentKind.MEAL_VOUCHER, false, 4);
            pay("OTHER", "Autre", Enums.PaymentKind.OTHER, false, 5);
        }
        if (destRepo.count() == 0) {
            dest("CLIENT", "Ticket client", Enums.DestinationKind.CUSTOMER, 1, true, 0); dest("CUISINE", "Cuisine", Enums.DestinationKind.PREP, 1, false, 1);
            dest("PIZZA", "Pizza", Enums.DestinationKind.PREP, 1, false, 2); dest("BOISSONS", "Boissons", Enums.DestinationKind.PREP, 1, false, 3);
            dest("PASSE", "Passe", Enums.DestinationKind.PREP, 0, false, 4);
        }
        if (templateRepo.count() == 0) {
            ReceiptTemplate t = new ReceiptTemplate();
            t.setCode("DEFAULT"); t.setName("Ticket standard 80 mm"); t.setPaperWidth(80); t.setFontSize(12); t.setMarginMm(3); t.setShowLogo(true);
            t.setFooterText("Merci pour votre visite !\nÀ bientôt");
            try { t.setConfigJson(om.writeValueAsString(ReceiptRenderer.defaultConfig())); } catch (Exception ignored) {}
            templateRepo.save(t);
        }
        if (userRepo.count() == 0) {
            Role admin = roleRepo.findByCode("ADMIN").orElseThrow();
            user("admin", "Administrateur", admin, "admin123", "9999", "#7c3aed");
        }
        log.info("PosCaisse: core data initialised (roles, payment methods, print destinations, admin user).");
    }

    private void seedDemo() {
        Company c = new Company();
        c.setName("FAST FOOD DEMO SARL"); c.setTradeName("FAST FOOD DEMO"); c.setAddress("12 Avenue Habib Bourguiba, Tunis 1000"); c.setPhone("+216 71 000 000");
        c.setTaxId("1234567/A/M/000"); c.setCurrency("TND"); c.setCurrencySymbol("DT"); c.setDecimals(3);
        c = companyRepo.save(c);
        PointOfSale pos = new PointOfSale(); pos.setCompany(c); pos.setCode("PV01"); pos.setName("CENTRE-VILLE"); pos.setAddress(c.getAddress()); pos.setPhone(c.getPhone());
        pos = posRepo.save(pos);
        Register r1 = new Register(); r1.setPointOfSale(pos); r1.setCode("C01"); r1.setName("CAISSE 01"); registerRepo.save(r1);
        Register r2 = new Register(); r2.setPointOfSale(pos); r2.setCode("C02"); r2.setName("CAISSE 02"); registerRepo.save(r2);

        Role manager = roleRepo.findByCode("MANAGER").orElseThrow(), cashier = roleRepo.findByCode("CASHIER").orElseThrow();
        user("manager", "Manager Démo", manager, "manager123", "2222", "#0ea5e9");
        User ahmed = user("ahmed", "Ahmed", cashier, null, "1234", "#f97316");
        User sami = user("sami", "Sami", cashier, null, "5678", "#22c55e");
        User mariem = user("mariem", "Mariem", cashier, null, "4321", "#ec4899");
        for (User u : List.of(ahmed, sami, mariem)) { u.setPointOfSale(pos); u.setMaxDiscountPercent(new BigDecimal("10")); userRepo.save(u); }

        PrintDestination cuisine = destRepo.findByCode("CUISINE").orElseThrow(), pizza = destRepo.findByCode("PIZZA").orElseThrow(), boissons = destRepo.findByCode("BOISSONS").orElseThrow();

        Category burgers = cat("Burgers", "#f97316", "🍔", 1, cuisine), sandwichs = cat("Sandwichs", "#eab308", "🥪", 2, cuisine), pizzas = cat("Pizzas", "#ef4444", "🍕", 3, pizza),
                menus = cat("Menus", "#8b5cf6", "🍱", 4, cuisine), drinks = cat("Boissons", "#0ea5e9", "🥤", 5, boissons), desserts = cat("Desserts", "#ec4899", "🍰", 6, null),
                extras = cat("Extras", "#22c55e", "🍟", 7, cuisine), salads = cat("Salades", "#10b981", "🥗", 8, cuisine);

        ModifierGroup burgerRemove = group("Burger — sans", false, true, 0, 0, 1, mod("Sans oignon", 0), mod("Sans tomate", 0), mod("Sans sauce", 0), mod("Sans salade", 0), mod("Sans cornichon", 0));
        ModifierGroup burgerExtra = group("Suppléments burger", false, true, 0, 4, 2, mod("Supplément fromage", 1.000), mod("Supplément viande", 3.000), mod("Supplément œuf", 1.000), mod("Supplément bacon", 1.500));
        ModifierGroup cuisson = group("Cuisson", false, false, 0, 1, 3, mod("Saignant", 0), mod("À point", 0), mod("Bien cuit", 0));
        ModifierGroup pizzaSize = group("Taille pizza", true, false, 1, 1, 4, mod("Petite", 0), mod("Moyenne", 3.000), mod("Grande", 6.000));
        ModifierGroup pizzaExtra = group("Suppléments pizza", false, true, 0, 5, 5, mod("Supplément fromage", 2.000), mod("Supplément thon", 2.500), mod("Supplément jambon", 2.000), mod("Champignons", 1.500), mod("Olives", 1.000));
        ModifierGroup sauces = group("Sauces", false, true, 0, 3, 6, mod("Harissa", 0), mod("Mayonnaise", 0), mod("Ketchup", 0), mod("Sauce algérienne", 0.500), mod("Sauce blanche", 0.500));
        ModifierGroup sandwichExtra = group("Suppléments sandwich", false, true, 0, 4, 7, mod("Supplément fromage", 1.000), mod("Supplément escalope", 3.000), mod("Frites dedans", 1.000));
        ModifierGroup drinkTemp = group("Boisson", false, false, 0, 1, 8, mod("Fraîche", 0), mod("Sans glaçons", 0));
        ModifierGroup saladeDressing = group("Assaisonnement", false, false, 0, 1, 9, mod("Vinaigrette", 0), mod("Sauce césar", 0), mod("Sans sauce", 0));

        // products (code, name, short, category, price, color, favorite, groups...)
        Product hamburger = prod("BUR-001", "Hamburger", "Hamburger", burgers, 6.500, true, 1, burgerRemove, burgerExtra, cuisson);
        Product cheese = prod("BUR-002", "Cheeseburger", "Cheeseburger", burgers, 7.500, true, 2, burgerRemove, burgerExtra, cuisson);
        Product doubleCheese = prod("BUR-003", "Double Cheese", "Dbl Cheese", burgers, 10.500, true, 3, burgerRemove, burgerExtra, cuisson);
        Product chicken = prod("BUR-004", "Chicken Burger", "Chicken Burg", burgers, 8.000, false, 4, burgerRemove, burgerExtra);
        Product fish = prod("BUR-005", "Fish Burger", "Fish Burger", burgers, 8.500, false, 5, burgerRemove, burgerExtra);
        Product escalope = prod("SAN-001", "Sandwich Escalope", "Escalope", sandwichs, 7.000, true, 6, sauces, sandwichExtra);
        Product chawarma = prod("SAN-002", "Sandwich Chawarma", "Chawarma", sandwichs, 7.500, true, 7, sauces, sandwichExtra);
        Product thon = prod("SAN-003", "Sandwich Thon", "Sand. Thon", sandwichs, 5.500, false, 8, sauces, sandwichExtra);
        Product merguez = prod("SAN-004", "Sandwich Merguez", "Merguez", sandwichs, 6.500, false, 9, sauces, sandwichExtra);
        Product kebab = prod("SAN-005", "Sandwich Kebab", "Kebab", sandwichs, 8.000, false, 10, sauces, sandwichExtra);
        Product margherita = prod("PIZ-001", "Pizza Margherita", "Margherita", pizzas, 9.000, true, 11, pizzaSize, pizzaExtra);
        Product fromages = prod("PIZ-002", "Pizza 4 Fromages", "4 Fromages", pizzas, 13.000, false, 12, pizzaSize, pizzaExtra);
        Product pepperoni = prod("PIZ-003", "Pizza Pepperoni", "Pepperoni", pizzas, 12.000, true, 13, pizzaSize, pizzaExtra);
        Product pizzaThon = prod("PIZ-004", "Pizza Thon", "Pizza Thon", pizzas, 11.000, false, 14, pizzaSize, pizzaExtra);
        Product reine = prod("PIZ-005", "Pizza Reine", "Reine", pizzas, 12.500, false, 15, pizzaSize, pizzaExtra);
        Product eau = prod("BOI-001", "Eau minérale 50cl", "Eau 50cl", drinks, 1.000, true, 16, drinkTemp);
        Product coca = prod("BOI-002", "Coca-Cola 33cl", "Coca 33cl", drinks, 2.500, true, 17, drinkTemp);
        Product fanta = prod("BOI-003", "Fanta 33cl", "Fanta 33cl", drinks, 2.500, false, 18, drinkTemp);
        Product boga = prod("BOI-004", "Boga 33cl", "Boga 33cl", drinks, 2.500, false, 19, drinkTemp);
        Product jus = prod("BOI-005", "Jus d'orange pressé", "Jus orange", drinks, 4.000, false, 20, drinkTemp);
        Product cafe = prod("BOI-006", "Café express", "Café", drinks, 1.500, false, 21);
        Product the = prod("BOI-007", "Thé à la menthe", "Thé menthe", drinks, 1.500, false, 22);
        Product tiramisu = prod("DES-001", "Tiramisu", "Tiramisu", desserts, 4.500, false, 23);
        Product fondant = prod("DES-002", "Fondant au chocolat", "Fondant choc", desserts, 5.000, false, 24);
        Product glace = prod("DES-003", "Glace 2 boules", "Glace", desserts, 3.500, false, 25);
        Product zlebia = prod("DES-004", "Zlebia", "Zlebia", desserts, 2.000, false, 26);
        Product frites = prod("EXT-001", "Frites", "Frites", extras, 3.000, true, 27, sauces);
        Product fritesL = prod("EXT-002", "Grande Frites", "Gde Frites", extras, 4.500, false, 28, sauces);
        Product extFromage = prod("EXT-003", "Portion fromage", "Fromage", extras, 1.500, false, 29);
        Product extSauce = prod("EXT-004", "Sauce (portion)", "Sauce", extras, 0.500, false, 30);
        Product extViande = prod("EXT-005", "Viande supplémentaire", "Sup. viande", extras, 3.000, false, 31);
        Product nuggets = prod("EXT-006", "Nuggets x6", "Nuggets", extras, 5.000, false, 32, sauces);
        Product saladeCesar = prod("SAL-001", "Salade César", "Salade César", salads, 8.500, false, 33, saladeDressing);
        Product saladeTun = prod("SAL-002", "Salade tunisienne", "Salade tun.", salads, 4.500, false, 34, saladeDressing);
        Product saladeMechouia = prod("SAL-003", "Salade méchouia", "Méchouia", salads, 4.000, false, 35);

        // menus
        Product menuBurger = menu("MEN-001", "Menu Burger", menus, 15.000, 36,
                comp("Burger", 1, opt(hamburger, 0), opt(cheese, 0), opt(chicken, 0.500), opt(doubleCheese, 2.000)),
                comp("Accompagnement", 1, opt(frites, 0), opt(fritesL, 1.000), opt(nuggets, 1.500)),
                comp("Boisson", 1, opt(coca, 0), opt(fanta, 0), opt(boga, 0), opt(eau, 0), opt(jus, 1.500)));
        Product menuPizza = menu("MEN-002", "Menu Pizza", menus, 14.000, 37,
                comp("Pizza", 1, opt(margherita, 0), opt(pizzaThon, 1.000), opt(pepperoni, 2.000), opt(fromages, 3.000)),
                comp("Boisson", 1, opt(coca, 0), opt(fanta, 0), opt(boga, 0), opt(eau, 0)));
        Product menuSandwich = menu("MEN-003", "Menu Sandwich", menus, 12.000, 38,
                comp("Sandwich", 1, opt(escalope, 0), opt(thon, 0), opt(merguez, 0), opt(chawarma, 0.500), opt(kebab, 1.000)),
                comp("Accompagnement", 1, opt(frites, 0), opt(saladeTun, 0)),
                comp("Boisson", 1, opt(coca, 0), opt(fanta, 0), opt(boga, 0), opt(eau, 0)));
        Product menuEnfant = menu("MEN-004", "Menu Enfant", menus, 9.000, 39,
                comp("Plat", 1, opt(hamburger, 0), opt(nuggets, 0)),
                comp("Accompagnement", 1, opt(frites, 0)),
                comp("Boisson", 1, opt(eau, 0), opt(jus, 1.000)));
        menuBurger.setFavorite(true); menuBurger.setFavoriteOrder(4); productRepo.save(menuBurger);
        List.of(menuPizza, menuSandwich, menuEnfant, saladeCesar, saladeMechouia, extFromage, extSauce, extViande, tiramisu, fondant, glace, zlebia, cafe, the, fish, reine).forEach(productRepo::save);

        Customer c1 = new Customer(); c1.setName("Client fidèle — Karim"); c1.setPhone("+216 20 000 000"); customerRepo.save(c1);
        Customer c2 = new Customer(); c2.setName("Société ABC (livraisons)"); c2.setPhone("+216 71 111 111"); c2.setNote("Livraison bureau 3e étage"); customerRepo.save(c2);
        log.info("PosCaisse: demo dataset created (FAST FOOD DEMO, {} products).", productRepo.count());
    }

    // ---------- helpers ----------
    private Role role(String code, String name, Set<Permission> perms) {
        Role r = new Role(); r.setCode(code); r.setName(name); r.setSystemRole(true); r.setPermissions(EnumSet.copyOf(perms)); return roleRepo.save(r);
    }
    private User user(String username, String fullName, Role role, String password, String pin, String color) {
        User u = new User(); u.setUsername(username); u.setFullName(fullName); u.setRole(role); u.setColor(color);
        if (password != null) u.setPasswordHash(encoder.encode(password));
        if (pin != null) u.setPinHash(encoder.encode(pin));
        return userRepo.save(u);
    }
    private void pay(String code, String name, Enums.PaymentKind kind, boolean drawer, int order) {
        PaymentMethod m = new PaymentMethod(); m.setCode(code); m.setName(name); m.setKind(kind); m.setOpensDrawer(drawer); m.setSortOrder(order); paymentRepo.save(m);
    }
    private void dest(String code, String name, Enums.DestinationKind kind, int copies, boolean prices, int order) {
        PrintDestination d = new PrintDestination(); d.setCode(code); d.setName(name); d.setKind(kind); d.setCopies(copies); d.setShowPrices(prices); d.setSortOrder(order); destRepo.save(d);
    }
    private Category cat(String name, String color, String icon, int order, PrintDestination dest) {
        Category c = new Category(); c.setName(name); c.setColor(color); c.setIcon(icon); c.setSortOrder(order); c.setPrintDestination(dest); return categoryRepo.save(c);
    }
    private record ModSpec(String name, double delta) {}
    private static ModSpec mod(String name, double delta) { return new ModSpec(name, delta); }
    private ModifierGroup group(String name, boolean required, boolean multiple, int min, int max, int order, ModSpec... mods) {
        ModifierGroup g = new ModifierGroup(); g.setName(name); g.setRequired(required); g.setMultiple(multiple); g.setMinSelect(min); g.setMaxSelect(max); g.setSortOrder(order);
        int i = 0;
        for (ModSpec s : mods) { Modifier m = new Modifier(); m.setGroup(g); m.setName(s.name()); m.setPriceDelta(BigDecimal.valueOf(s.delta()).setScale(3)); m.setSortOrder(i++); g.getModifiers().add(m); }
        return groupRepo.save(g);
    }
    private Product prod(String code, String name, String shortName, Category cat, double price, boolean fav, int order, ModifierGroup... groups) {
        Product p = new Product(); p.setCode(code); p.setName(name); p.setShortName(shortName); p.setCategory(cat); p.setPrice(BigDecimal.valueOf(price).setScale(3));
        p.setSortOrder(order); p.setFavorite(fav); p.setFavoriteOrder(fav ? order : 0); p.setColor(cat.getColor());
        int i = 0;
        for (ModifierGroup g : groups) { ProductModifierGroup pmg = new ProductModifierGroup(); pmg.setProduct(p); pmg.setModifierGroup(g); pmg.setSortOrder(i++); p.getModifierGroups().add(pmg); }
        return productRepo.save(p);
    }
    private record OptSpec(Product product, double delta) {}
    private static OptSpec opt(Product p, double delta) { return new OptSpec(p, delta); }
    private record CompSpec(String name, int qty, OptSpec[] options) {}
    private static CompSpec comp(String name, int qty, OptSpec... options) { return new CompSpec(name, qty, options); }
    private Product menu(String code, String name, Category cat, double price, int order, CompSpec... comps) {
        Product p = new Product(); p.setCode(code); p.setName(name); p.setShortName(name); p.setCategory(cat); p.setPrice(BigDecimal.valueOf(price).setScale(3));
        p.setProductType(Enums.ProductType.MENU); p.setSortOrder(order); p.setColor(cat.getColor());
        int i = 0;
        for (CompSpec cs : comps) {
            MenuComponent mc = new MenuComponent(); mc.setMenuProduct(p); mc.setName(cs.name()); mc.setQuantity(cs.qty()); mc.setSortOrder(i++);
            for (OptSpec o : cs.options()) { MenuComponentProduct mcp = new MenuComponentProduct(); mcp.setComponent(mc); mcp.setProduct(o.product()); mcp.setPriceDelta(BigDecimal.valueOf(o.delta()).setScale(3)); mc.getOptions().add(mcp); }
            p.getMenuComponents().add(mc);
        }
        return productRepo.save(p);
    }
}
