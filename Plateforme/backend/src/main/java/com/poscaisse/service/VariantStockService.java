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
 * Le stock des pates, par point de vente.
 *
 * CE QUI SE COMPTE. Pas un article : la PATE. La meme pate normale sert quarante
 * sandwichs differents, et c'est elle qui manque a 21 h. Le compteur se pose donc sur la
 * valeur de variante, la ou la penurie se produit.
 *
 * QUI EMPRUNTE A QUI. Une valeur peut ne pas avoir de compteur et tirer sur une autre :
 * << Double Normale >> consomme deux pates normales. C'est la meme pate au frigo, comptee
 * deux fois. Un seul saut est permis - une source qui tirerait elle-meme sur une
 * troisieme valeur est refusee a l'enregistrement, faute de quoi une chaine cassee
 * ferait disparaitre la decrementation sans que personne ne s'en apercoive.
 *
 * POURQUOI UN VERROU. Deux caisses peuvent encaisser la meme seconde. Sans verrou, toutes
 * deux lisent << il reste 1 >>, toutes deux acceptent, et un client attend un sandwich qui
 * n'existe pas. Chaque compteur touche par une vente est donc verrouille jusqu'a la fin
 * de la transaction.
 */
@Service @RequiredArgsConstructor
public class VariantStockService {
    private static final ZoneId TZ = ZoneId.of("Africa/Tunis");
    private final VariantStockRepo stockRepo;
    private final VariantStockMovementRepo movementRepo;
    private final VariantValueRepo valueRepo;
    private final PointOfSaleRepo posRepo;
    private final CurrentUser currentUser;
    private final JournalService journal;
    private final AuditService audit;
    private final SessionRepo sessionRepo;

    // ------------------------------------------------------------------ lecture

    @Transactional(readOnly = true)
    public StockStateDto etat(Long posId) {
        PointOfSale pos = posRepo.findById(posId).orElseThrow(() -> BusinessException.notFound("Point de vente"));
        Map<Long, BigDecimal> compteurs = new HashMap<>();
        for (VariantStock s : stockRepo.findByPointOfSaleId(posId)) compteurs.put(s.getVariantValue().getId(), s.getQuantity());
        List<StockLineDto> lignes = new ArrayList<>();
        for (VariantValue v : suivies()) {
            lignes.add(new StockLineDto(v.getId(), v.getVariant().getName(), v.getName(),
                    Money.r(compteurs.getOrDefault(v.getId(), BigDecimal.ZERO)), emprunteurs(v)));
        }
        OffsetDateTime debutJour = LocalDate.now(TZ).atStartOfDay(TZ).toOffsetDateTime();
        List<StockMovementDto> mouvements = movementRepo
                .findByPointOfSaleIdAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(posId, debutJour)
                .stream().map(m -> new StockMovementDto(m.getId(), m.getVariantValue().getId(), m.getVariantValue().getName(),
                        m.getMovementType().name(), m.getQuantity(), m.getResulting(),
                        m.getUser() == null ? null : m.getUser().getFullName(), m.getComment(), m.getCreatedAt()))
                .toList();
        return new StockStateDto(pos.getId(), pos.getName(), lignes, mouvements);
    }

    /**
     * Les compteurs, pour le back-office : ce qu'il reste, point de vente par point de vente.
     *
     * L'ecran des variantes n'a pas de caisse ouverte derriere lui - le gerant y regarde
     * un reglage, pas une session. On ne peut donc pas lui servir etat(posId), qui part
     * de la caisse du caissier : on lit tous les compteurs, et l'ecran nomme le point de
     * vente en face de chaque quantite.
     */
    @Transactional(readOnly = true)
    public List<StockCounterDto> compteurs() {
        return stockRepo.findAll().stream()
                .filter(s -> s.getVariantValue() != null && s.getPointOfSale() != null)
                .sorted(Comparator.comparing((VariantStock s) -> s.getPointOfSale().getId())
                        .thenComparing(s -> s.getVariantValue().getId()))
                .map(s -> new StockCounterDto(s.getVariantValue().getId(), s.getPointOfSale().getId(),
                        s.getPointOfSale().getName(), Money.r(s.getQuantity()), s.getUpdatedAt()))
                .toList();
    }

    /** Les valeurs qui portent un compteur, dans l'ordre ou l'ecran les montre. */
    private List<VariantValue> suivies() {
        return valueRepo.findAll().stream()
                .filter(v -> v.isStockManaged() && v.isActive() && v.getVariant() != null && v.getVariant().isActive())
                .sorted(Comparator.comparingInt((VariantValue v) -> v.getVariant().getSortOrder())
                        .thenComparingInt(VariantValue::getSortOrder).thenComparing(VariantValue::getId))
                .toList();
    }

    /** Ce qui tire sur cette valeur, dit tel quel : << Double Normale x2 >>. */
    private List<String> emprunteurs(VariantValue porteur) {
        return valueRepo.findAll().stream()
                .filter(v -> v.isActive() && v.getStockSource() != null && v.getStockSource().getId().equals(porteur.getId()))
                .sorted(Comparator.comparingInt(VariantValue::getSortOrder).thenComparing(VariantValue::getId))
                .map(v -> v.getName() + " x" + pas(v.getStockStep()))
                .toList();
    }

    private static String pas(BigDecimal v) {
        return Money.nz(v).stripTrailingZeros().toPlainString();
    }

    // ------------------------------------------------------------------ vente

    /**
     * Ce qu'une commande retire, compteur par compteur.
     *
     * Toutes les lignes comptent, y compris les composants d'un menu - le sandwich d'un
     * menu consomme une pate comme un autre. La quantite d'un composant est multipliee
     * par celle du menu : deux menus font deux sandwichs, donc deux pates, quelle que
     * soit la facon dont le tarif est calcule par ailleurs.
     */
    private Map<Long, BigDecimal> besoins(SaleOrder o) {
        Map<Long, BigDecimal> besoins = new LinkedHashMap<>();
        for (OrderLine l : o.getLines()) ajouter(besoins, l, l.getParentLine() == null ? BigDecimal.ONE : Money.nz(l.getParentLine().getQuantity()));
        return besoins;
    }

    private void ajouter(Map<Long, BigDecimal> besoins, OrderLine l, BigDecimal facteur) {
        VariantValue v = l.getVariantValue();
        if (v == null) return;
        VariantValue porteur = v.stockPorteur();
        if (porteur == null) return;
        BigDecimal q = Money.nz(l.getQuantity()).multiply(facteur).multiply(Money.nz(v.getStockStep()));
        besoins.merge(porteur.getId(), q, BigDecimal::add);
    }

    /**
     * Retire de la commande ce qu'elle consomme, ou refuse la vente.
     *
     * Le refus nomme la pate et donne les deux chiffres : le caissier est devant un
     * client, il doit savoir en une phrase quoi proposer a la place.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public void consommer(SaleOrder o) {
        besoins(o).forEach((valueId, besoin) -> {
            if (besoin.signum() <= 0) return;
            VariantStock s = verrou(o.getPointOfSale(), valueId);
            if (s.getQuantity().compareTo(besoin) < 0)
                throw new BusinessException("Stock insuffisant : il reste " + pas(s.getQuantity()) + " « "
                        + s.getVariantValue().getName() + " » et il en faut " + pas(besoin) + ".");
            poser(s, besoin.negate(), Enums.StockMovement.VENTE, o, o.getCashier(), null);
        });
    }

    /**
     * Rend au stock ce qu'un ticket annule avait consomme.
     *
     * Une annulation est presque toujours une erreur de saisie : le sandwich n'a pas ete
     * fait, la pate est encore la. Un remboursement, lui, ne rend rien - il arrive apres
     * coup, la pate est cuite et perdue.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public void restituer(SaleOrder o) {
        besoins(o).forEach((valueId, besoin) -> {
            if (besoin.signum() <= 0) return;
            poser(verrou(o.getPointOfSale(), valueId), besoin, Enums.StockMovement.ANNULATION, o, currentUser.entity(), null);
        });
    }

    // ------------------------------------------------------------------ saisie

    /** Reception de pates : le compteur monte, le journal de caisse le dit. */
    @Transactional
    public StockStateDto entrer(Long posId, StockMoveRequest req) {
        return saisie(posId, req, true);
    }

    /** Pate dechiree, abimee, tombee : le compteur descend, avec le motif. */
    @Transactional
    public StockStateDto casser(Long posId, StockMoveRequest req) {
        return saisie(posId, req, false);
    }

    private StockStateDto saisie(Long posId, StockMoveRequest req, boolean entree) {
        currentUser.require(Permission.SELL, "Vous n'avez pas la permission de tenir le stock.");
        if (req.quantity() == null || req.quantity().signum() <= 0)
            throw new BusinessException("La quantité doit être supérieure à zéro.");
        PointOfSale pos = posRepo.findById(posId).orElseThrow(() -> BusinessException.notFound("Point de vente"));
        VariantValue v = valueRepo.findById(req.variantValueId()).orElseThrow(() -> BusinessException.notFound("Valeur de variante"));
        if (!v.isStockManaged())
            throw new BusinessException("« " + v.getName() + " » n'est pas suivie en stock : activez le suivi dans les variantes.");
        User me = currentUser.entity();
        VariantStock s = verrou(pos, v.getId());
        BigDecimal delta = entree ? Money.r(req.quantity()) : Money.r(req.quantity()).negate();
        // La casse ne peut pas creuser un trou : declarer plus de pates perdues qu'il n'en
        // reste est une erreur de saisie, pas un stock negatif.
        if (!entree && s.getQuantity().add(delta).signum() < 0)
            throw new BusinessException("Il ne reste que " + pas(s.getQuantity()) + " « " + v.getName() + " » : impossible d'en retirer " + pas(req.quantity()) + ".");
        poser(s, delta, entree ? Enums.StockMovement.ENTREE : Enums.StockMovement.CASSE, null, me, req.comment());

        // Le journal de caisse porte la trace, avec le nom : c'est la ou le gerant regarde
        // quand un stock ne tombe pas juste. La quantite y tient la place du montant.
        RegisterSession session = sessionRepo.findFirstByOpenedByIdAndStatusOrderByOpenedAtDesc(me.getId(), Enums.SessionStatus.OPEN).orElse(null);
        String quoi = (entree ? "Entrée stock " : "Casse ") + pas(req.quantity()) + " « " + v.getName() + " »"
                + (req.comment() == null || req.comment().isBlank() ? "" : " — " + req.comment().trim());
        if (session != null)
            journal.record(session, me, entree ? Enums.JournalEvent.STOCK_IN : Enums.JournalEvent.STOCK_OUT,
                    Money.r(req.quantity()), null, quoi);
        else
            journal.recordForPos(pos, me, entree ? Enums.JournalEvent.STOCK_IN : Enums.JournalEvent.STOCK_OUT,
                    Money.r(req.quantity()), null, quoi);
        audit.log(entree ? "STOCK_IN" : "STOCK_OUT", "VariantValue", v.getId(), quoi + " → " + pas(s.getQuantity()));
        return etat(posId);
    }

    // ------------------------------------------------------------------ cloture

    /**
     * Remise a zero, a la cloture journaliere.
     *
     * La pate ne se garde pas d'un jour a l'autre : un report ferait croire au matin a un
     * stock qui n'existe plus. Ce qui restait est ecrit dans le mouvement, pour qu'on
     * puisse savoir le lendemain ce qui a ete jete.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public int remiseAZero(PointOfSale pos, User by) {
        int n = 0;
        for (VariantStock s : stockRepo.findByPointOfSaleId(pos.getId())) {
            if (s.getQuantity().signum() == 0) continue;
            poser(s, s.getQuantity().negate(), Enums.StockMovement.REMISE_A_ZERO, null, by, "Clôture journalière");
            n++;
        }
        return n;
    }

    // ------------------------------------------------------------------ mecanique

    /** Le compteur, verrouille ; il est cree a zero s'il n'existe pas encore. */
    private VariantStock verrou(PointOfSale pos, Long valueId) {
        return stockRepo.lock(pos.getId(), valueId).orElseGet(() -> {
            VariantStock s = new VariantStock();
            s.setPointOfSale(pos);
            s.setVariantValue(valueRepo.getReferenceById(valueId));
            s.setQuantity(BigDecimal.ZERO);
            // saveAndFlush : la ligne doit exister avant que la transaction suivante ne la
            // cherche, sinon deux ventes simultanees en creeraient deux.
            return stockRepo.saveAndFlush(s);
        });
    }

    private void poser(VariantStock s, BigDecimal delta, Enums.StockMovement type, SaleOrder order, User by, String comment) {
        s.setQuantity(Money.r(s.getQuantity().add(delta)));
        s.setUpdatedAt(OffsetDateTime.now());
        stockRepo.save(s);
        VariantStockMovement m = new VariantStockMovement();
        m.setPointOfSale(s.getPointOfSale());
        m.setVariantValue(s.getVariantValue());
        m.setMovementType(type);
        m.setQuantity(Money.r(delta));
        m.setResulting(s.getQuantity());
        m.setOrder(order);
        m.setUser(by);
        m.setComment(comment);
        movementRepo.save(m);
    }
}
