package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.*;
import com.poscaisse.dto.StockDtos.*;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.*;
import com.poscaisse.security.CurrentUser;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.*;

/**
 * Le stock d'une boutique : ce qui a ete achete, ce qui a ete vendu, ce qui reste.
 *
 * CE QUI SE COMPTE ICI. L'ARTICLE - la bouteille, le paquet, la recharge. C'est ce qui
 * porte un code-barres et ce qui s'achete a un fournisseur. Le restaurant, lui, compte sa
 * PATE : voir {@link VariantStockService}, qui pose le compteur sur la valeur de variante.
 * Les deux vivent cote a cote sans se rencontrer ; une meme maison peut tenir les deux.
 *
 * TROIS REGLAGES COMMANDENT TOUT.
 *   - << stock.mode >> : personne n'est compte, certains articles le sont (le cas courant),
 *     ou tous. En mode << total >>, un article neuf est compte sans qu'on ait rien a cocher.
 *   - << stock.rupture >> : refuser la vente, avertir, ou laisser passer. Un fast-food
 *     refuse ; une boutique de quartier prefere souvent vendre et regulariser le soir.
 *   - << stock.entree >> : le stock entre par un achat trace (fournisseur, prix) ou par une
 *     saisie libre.
 *
 * POURQUOI UN VERROU. Deux caisses peuvent encaisser la meme seconde. Sans verrou, toutes
 * deux lisent << il en reste 1 >>, toutes deux acceptent, et un client repart sans son
 * article. Chaque compteur touche par une vente est donc verrouille jusqu'a la fin de la
 * transaction.
 */
@Service @RequiredArgsConstructor
public class ProductStockService {
    private static final ZoneId TZ = ZoneId.of("Africa/Tunis");

    private final ProductStockRepo stockRepo;
    private final ProductStockMovementRepo movementRepo;
    private final ProductRepo productRepo;
    private final PointOfSaleRepo posRepo;
    private final CurrentUser currentUser;
    private final SettingsService settings;
    private final JournalService journal;
    private final AuditService audit;
    private final SessionRepo sessionRepo;

    // ------------------------------------------------------------------ les reglages

    /** << aucun >>, << partiel >> ou << total >>. */
    public String mode() {
        String m = settings.get(SettingsService.STOCK_MODE);
        return m == null || m.isBlank() ? "partiel" : m.trim().toLowerCase();
    }

    /** << refuser >>, << avertir >> ou << passer >>. */
    public String rupture() {
        String r = settings.get(SettingsService.STOCK_RUPTURE);
        return r == null || r.isBlank() ? "refuser" : r.trim().toLowerCase();
    }

    /**
     * Cet article est-il compte ?
     *
     * En mode << total >>, tout ce qui se vend l'est - y compris l'article ajoute ce matin
     * et sur lequel personne n'a pense a cocher la case. C'est justement ce que le mode
     * promet ; le laisser dependre d'une case a cocher le viderait de son sens.
     */
    public boolean suivi(Product p) {
        if (p == null) return false;
        String m = mode();
        if ("aucun".equals(m)) return false;
        if ("total".equals(m)) return p.getProductType() != Enums.ProductType.MENU;
        return p.isStockManaged();
    }

    // ------------------------------------------------------------------ lecture

    @Transactional(readOnly = true)
    public ProductStockStateDto etat(Long posId) {
        PointOfSale pos = posRepo.findById(posId).orElseThrow(() -> BusinessException.notFound("Point de vente"));
        Map<Long, BigDecimal> compteurs = new HashMap<>();
        for (ProductStock s : stockRepo.findByPointOfSaleId(posId)) compteurs.put(s.getProduct().getId(), s.getQuantity());

        List<ProductStockLineDto> lignes = new ArrayList<>();
        for (Product p : productRepo.findByActiveTrueOrderBySortOrderAscNameAsc()) {
            if (!suivi(p)) continue;
            BigDecimal q = Money.r(compteurs.getOrDefault(p.getId(), BigDecimal.ZERO));
            BigDecimal seuil = Money.nz(p.getStockMin());
            lignes.add(new ProductStockLineDto(p.getId(), p.getCode(), p.getBarcode(), p.getName(),
                    p.getCategory() == null ? null : p.getCategory().getName(),
                    q, seuil, Money.nz(p.getPurchasePrice()), Money.nz(p.getPrice()),
                    q.compareTo(seuil) <= 0));
        }

        OffsetDateTime debutJour = LocalDate.now(TZ).atStartOfDay(TZ).toOffsetDateTime();
        List<ProductStockMovementDto> mouvements = movementRepo
                .findByPointOfSaleIdAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(posId, debutJour)
                .stream().map(this::dto).toList();

        return new ProductStockStateDto(pos.getId(), pos.getName(), mode(), rupture(), lignes, mouvements);
    }

    @Transactional(readOnly = true)
    public List<ProductStockMovementDto> historique(Long productId) {
        return movementRepo.findTop50ByProductIdOrderByCreatedAtDesc(productId).stream().map(this::dto).toList();
    }

    private ProductStockMovementDto dto(ProductStockMovement m) {
        return new ProductStockMovementDto(m.getId(), m.getProduct().getId(), m.getProduct().getName(),
                m.getMovementType().name(), m.getQuantity(), m.getResulting(), m.getUnitCost(),
                m.getSupplier(), m.getUser() == null ? null : m.getUser().getFullName(),
                m.getComment(), m.getCreatedAt());
    }

    // ------------------------------------------------------------------ vente

    /**
     * Ce qu'une commande retire, article par article.
     *
     * Les composants d'un menu comptent aussi : la bouteille du menu sort du meme rayon
     * que celle vendue seule. Sa quantite est multipliee par celle du menu.
     */
    private Map<Long, BigDecimal> besoins(SaleOrder o) {
        Map<Long, BigDecimal> besoins = new LinkedHashMap<>();
        for (OrderLine l : o.getLines()) {
            Product p = l.getProduct();
            if (!suivi(p)) continue;
            BigDecimal facteur = l.getParentLine() == null ? BigDecimal.ONE : Money.nz(l.getParentLine().getQuantity());
            besoins.merge(p.getId(), Money.nz(l.getQuantity()).multiply(facteur), BigDecimal::add);
        }
        return besoins;
    }

    /**
     * Retire de la commande ce qu'elle consomme, ou refuse la vente.
     *
     * Le refus nomme l'article et donne les deux chiffres : le caissier a un client devant
     * lui, il doit savoir en une phrase ce qui manque. Selon le reglage, la penurie peut
     * n'etre qu'un avertissement - le compteur descend alors dans le negatif, ce qui est
     * exactement l'information dont le gerant a besoin le soir.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public void consommer(SaleOrder o) {
        if ("aucun".equals(mode())) return;
        boolean refuse = "refuser".equals(rupture());
        besoins(o).forEach((productId, besoin) -> {
            if (besoin.signum() <= 0) return;
            ProductStock s = verrou(o.getPointOfSale(), productId);
            if (refuse && s.getQuantity().compareTo(besoin) < 0)
                throw new BusinessException("Stock insuffisant : il reste " + nb(s.getQuantity()) + " « "
                        + s.getProduct().getName() + " » et il en faut " + nb(besoin) + ".");
            poser(s, besoin.negate(), Enums.StockMovement.VENTE, o, o.getCashier(), null, null, null);
        });
    }

    /**
     * Rend au stock ce qu'un ticket annule avait consomme.
     *
     * Une annulation est presque toujours une erreur de saisie : l'article n'a pas quitte
     * le rayon. Un remboursement, lui, ne rend rien tant que la marchandise n'est pas
     * revenue - c'est une entree a saisir, pas un automatisme.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public void restituer(SaleOrder o) {
        if ("aucun".equals(mode())) return;
        besoins(o).forEach((productId, besoin) -> {
            if (besoin.signum() <= 0) return;
            poser(verrou(o.getPointOfSale(), productId), besoin, Enums.StockMovement.ANNULATION, o,
                    currentUser.entity(), null, null, null);
        });
    }

    // ------------------------------------------------------------------ saisie

    /** Reception de marchandise : le compteur monte, le prix d'achat est garde. */
    @Transactional
    public ProductStockStateDto entrer(Long posId, ProductStockMoveRequest req) {
        Product p = exige(req, true);
        User me = currentUser.entity();
        PointOfSale pos = pos(posId);
        ProductStock s = verrou(pos, p.getId());
        BigDecimal cout = req.unitCost() == null ? null : Money.r(req.unitCost());
        poser(s, Money.r(req.quantity()), Enums.StockMovement.ENTREE, null, me, cout, req.supplier(), req.comment());
        // Le dernier prix d'achat connu suit l'entree : c'est lui qui pre-remplira la
        // prochaine, et qui sert de repere quand le gerant fixe son prix de vente.
        if (cout != null && cout.signum() > 0) { p.setPurchasePrice(cout); productRepo.save(p); }
        tracer(pos, me, true, p, req.quantity(), req.comment(), s.getQuantity());
        return etat(posId);
    }

    /** Casse, perte, peremption, vol : le compteur descend, avec le motif. */
    @Transactional
    public ProductStockStateDto casser(Long posId, ProductStockMoveRequest req) {
        Product p = exige(req, true);
        User me = currentUser.entity();
        PointOfSale pos = pos(posId);
        ProductStock s = verrou(pos, p.getId());
        BigDecimal delta = Money.r(req.quantity()).negate();
        if (s.getQuantity().add(delta).signum() < 0)
            throw new BusinessException("Il ne reste que " + nb(s.getQuantity()) + " « " + p.getName()
                    + " » : impossible d'en retirer " + nb(req.quantity()) + ".");
        poser(s, delta, Enums.StockMovement.CASSE, null, me, null, null, req.comment());
        tracer(pos, me, false, p, req.quantity(), req.comment(), s.getQuantity());
        return etat(posId);
    }

    /**
     * Inventaire : on POSE le chiffre compte, et l'ecart se deduit.
     *
     * C'est le seul mouvement ou la quantite saisie n'est pas un delta. Le faire saisir en
     * ecart obligerait le gerant a une soustraction devant son rayon, et c'est la que les
     * erreurs entrent.
     */
    @Transactional
    public ProductStockStateDto inventaire(Long posId, ProductStockMoveRequest req) {
        Product p = exige(req, false);
        if (req.quantity().signum() < 0) throw new BusinessException("Une quantité comptée ne peut pas être négative.");
        User me = currentUser.entity();
        PointOfSale pos = pos(posId);
        ProductStock s = verrou(pos, p.getId());
        BigDecimal ecart = Money.r(req.quantity()).subtract(s.getQuantity());
        if (ecart.signum() == 0) return etat(posId);
        poser(s, ecart, Enums.StockMovement.INVENTAIRE, null, me, null, null,
                req.comment() == null || req.comment().isBlank() ? "Inventaire" : req.comment().trim());
        audit.log("STOCK_INVENTAIRE", "Product", p.getId(),
                "Inventaire « " + p.getName() + " » → " + nb(s.getQuantity()) + " (écart " + nb(ecart) + ")");
        return etat(posId);
    }

    // ------------------------------------------------------------------ mecanique

    private Product exige(ProductStockMoveRequest req, boolean positif) {
        currentUser.require(Permission.SELL, "Vous n'avez pas la permission de tenir le stock.");
        if (req.quantity() == null || (positif && req.quantity().signum() <= 0))
            throw new BusinessException("La quantité doit être supérieure à zéro.");
        Product p = productRepo.findById(req.productId()).orElseThrow(() -> BusinessException.notFound("Article"));
        if (!suivi(p))
            throw new BusinessException("« " + p.getName() + " » n'est pas suivi en stock : activez le suivi dans sa fiche.");
        return p;
    }

    private PointOfSale pos(Long posId) {
        return posRepo.findById(posId).orElseThrow(() -> BusinessException.notFound("Point de vente"));
    }

    /**
     * Le journal de caisse porte la trace d'une entree ou d'une casse.
     *
     * C'est la que le gerant regarde quand un stock ne tombe pas juste, et il n'a pas a
     * ouvrir un autre ecran pour le savoir. La quantite y tient la place du montant.
     */
    private void tracer(PointOfSale pos, User me, boolean entree, Product p, BigDecimal q, String motif, BigDecimal reste) {
        String quoi = (entree ? "Entrée stock " : "Casse ") + nb(q) + " « " + p.getName() + " »"
                + (motif == null || motif.isBlank() ? "" : " — " + motif.trim());
        RegisterSession session = sessionRepo
                .findFirstByOpenedByIdAndStatusOrderByOpenedAtDesc(me.getId(), Enums.SessionStatus.OPEN).orElse(null);
        Enums.JournalEvent ev = entree ? Enums.JournalEvent.STOCK_IN : Enums.JournalEvent.STOCK_OUT;
        if (session != null) journal.record(session, me, ev, Money.r(q), null, quoi);
        else journal.recordForPos(pos, me, ev, Money.r(q), null, quoi);
        audit.log(entree ? "STOCK_IN" : "STOCK_OUT", "Product", p.getId(), quoi + " → " + nb(reste));
    }

    /** Le compteur, verrouille ; il est cree a zero s'il n'existe pas encore. */
    private ProductStock verrou(PointOfSale pos, Long productId) {
        return stockRepo.lock(pos.getId(), productId).orElseGet(() -> {
            ProductStock s = new ProductStock();
            s.setPointOfSale(pos);
            s.setProduct(productRepo.getReferenceById(productId));
            s.setQuantity(BigDecimal.ZERO);
            // saveAndFlush : la ligne doit exister avant que la transaction suivante ne la
            // cherche, sinon deux ventes simultanees en creeraient deux.
            return stockRepo.saveAndFlush(s);
        });
    }

    private void poser(ProductStock s, BigDecimal delta, Enums.StockMovement type, SaleOrder order,
                       User by, BigDecimal unitCost, String supplier, String comment) {
        s.setQuantity(Money.r(s.getQuantity().add(delta)));
        s.setUpdatedAt(OffsetDateTime.now());
        stockRepo.save(s);
        ProductStockMovement m = new ProductStockMovement();
        m.setPointOfSale(s.getPointOfSale());
        m.setProduct(s.getProduct());
        m.setMovementType(type);
        m.setQuantity(Money.r(delta));
        m.setResulting(s.getQuantity());
        m.setUnitCost(unitCost);
        m.setSupplier(supplier == null || supplier.isBlank() ? null : supplier.trim());
        m.setOrder(order);
        m.setUser(by);
        m.setComment(comment == null || comment.isBlank() ? null : comment.trim());
        movementRepo.save(m);
    }

    private static String nb(BigDecimal v) {
        return Money.nz(v).stripTrailingZeros().toPlainString();
    }
}
