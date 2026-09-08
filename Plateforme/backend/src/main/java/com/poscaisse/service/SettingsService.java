package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.AppSetting;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.SettingRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service @RequiredArgsConstructor
public class SettingsService {
    public static final String TICKET_PATTERN = "ticket.pattern";
    public static final String TICKET_RESET_PERIOD = "ticket.resetPeriod";
    public static final String TICKET_PER_POS = "ticket.perPos";
    public static final String TICKET_PER_REGISTER = "ticket.perRegister";
    public static final String TICKET_DISPLAY_PATTERN = "ticket.displayPattern";
    public static final String SERVICE_MODES = "pos.serviceModes";
    public static final String DEFAULT_SERVICE_MODE = "pos.defaultServiceMode";
    public static final String TAX_ENABLED = "tax.enabled";
    public static final String DISCOUNT_HIGH_THRESHOLD = "discount.highThresholdPercent";
    public static final String TILE_SIZE = "pos.tileSize";
    public static final String SHOW_IMAGES = "pos.showImages";
    public static final String AUTO_PRINT = "print.autoPreview";
    public static final String RECEIPT_TEMPLATE = "receipt.template";
    public static final String QUICK_CASH = "pos.quickCash";
    public static final String CASH_ROUNDING = "pos.cashRounding";
    public static final String PIN_USER_TILES = "auth.showUserTiles";
    /**
     * Marge beneficiaire, en pourcentage du chiffre d'affaires.
     *
     * C'est une ESTIMATION de gestion, pas une comptabilite : le logiciel ne connait pas
     * le prix d'achat des ingredients, seulement ce qui a ete vendu. Le restaurateur pose
     * le taux qu'il connait de son metier, et l'ecran de cloture en tire un montant.
     * A zero - la valeur livree - la ligne ne s'affiche pas du tout.
     */
    public static final String MARGIN_PERCENT = "finance.marginPercent";

    /*
        ------------------------------------------------------------------ le metier

        Ces reglages ne sont reserves a aucune verticale : ils portent une valeur de
        depart posee par le profil - boutique, restaurant, cafe - que le client change
        ensuite comme il veut. Un cafe qui decide de scanner ses bouteilles coche la
        case et cela marche ; une boutique qui ne veut pas compter son stock la decoche.
    */

    /** Le champ code-barres apparait sur la fiche article, et la caisse ecoute le scanner. */
    public static final String BARCODE_ENABLED = "catalog.barcode.enabled";
    /** Un scan ajoute directement au panier, sans passer par la fiche. */
    public static final String BARCODE_AUTO_ADD = "pos.barcode.autoAdd";
    /** Un code inconnu propose de creer l'article sur-le-champ, au lieu de ne rien dire. */
    public static final String BARCODE_UNKNOWN_ASK = "pos.barcode.unknownAsk";

    /**
     * Qui est compte : personne, certains articles, ou tous.
     *
     * << partiel >> est le cas courant et la valeur livree : la boutique suit ses
     * recharges et pas ses sacs plastique. << total >> force le suivi sur tout ce qui
     * entre au catalogue - a ne poser que si l'inventaire est deja tenu.
     */
    public static final String STOCK_MODE = "stock.mode";               // aucun | partiel | total
    /**
     * Ce qui arrive quand il n'y en a plus : refuser la vente, avertir sans bloquer, ou
     * laisser passer. Un fast-food refuse - il ne peut pas servir ce qu'il n'a pas ; une
     * boutique prefere parfois vendre et regulariser le soir.
     */
    public static final String STOCK_RUPTURE = "stock.rupture";         // refuser | avertir | passer
    /** Le stock entre par un ACHAT (fournisseur, prix d'achat) ou par une saisie libre. */
    public static final String STOCK_ENTREE = "stock.entree";           // achat | libre

    private static final Set<String> SENSITIVE = Set.of(TICKET_PATTERN, TICKET_RESET_PERIOD, TICKET_PER_POS,
            TICKET_PER_REGISTER, TICKET_DISPLAY_PATTERN, TAX_ENABLED, DISCOUNT_HIGH_THRESHOLD, MARGIN_PERCENT,
            BARCODE_ENABLED, STOCK_MODE, STOCK_RUPTURE, STOCK_ENTREE);
    /** Les quatre reglages du numero de ticket : ils ne se jugent qu'ensemble. */
    private static final Set<String> NUMEROTATION = Set.of(TICKET_PATTERN, TICKET_RESET_PERIOD,
            TICKET_PER_POS, TICKET_PER_REGISTER, TICKET_DISPLAY_PATTERN);

    private final SettingRepo repo;
    private final AuditService audit;

    public static Map<String, String> defaults() {
        Map<String, String> d = new LinkedHashMap<>();
        d.put(TICKET_PATTERN, "{POS}-{YYYY}-{SEQ:6}");
        // Ce que le format livre par defaut faisait deja : un compteur par point de vente,
        // remis a zero chaque annee. Dit maintenant, au lieu d'etre devine du format.
        d.put(TICKET_RESET_PERIOD, "YEARLY");
        d.put(TICKET_PER_POS, "true");
        d.put(TICKET_PER_REGISTER, "false");
        // Vide : le ticket montre sa reference entiere, comme avant. C'est en la
        // remplissant qu'on raccourcit ce que lisent le caissier et le client.
        d.put(TICKET_DISPLAY_PATTERN, "");
        d.put(SERVICE_MODES, "DINE_IN,TAKEAWAY,DELIVERY");
        d.put(DEFAULT_SERVICE_MODE, "TAKEAWAY");
        d.put(TAX_ENABLED, "false");
        d.put(DISCOUNT_HIGH_THRESHOLD, "10");
        d.put(TILE_SIZE, "M");
        d.put(SHOW_IMAGES, "true");
        d.put(AUTO_PRINT, "true");
        d.put(RECEIPT_TEMPLATE, "DEFAULT");
        d.put(QUICK_CASH, "5,10,20,50");
        d.put(CASH_ROUNDING, "0");
        d.put(PIN_USER_TILES, "true");
        // Zero : tant que le restaurateur n'a pas pose SON taux, aucun montant de benefice
        // ne s'affiche. Un taux invente serait pire que pas de taux du tout.
        d.put(MARGIN_PERCENT, "0");
        // Le profil livre decide de ces quatre-la ; ce sont les valeurs du metier de la
        // table - restaurant et cafe - ou rien ne se scanne et ou le stock se pose sur la
        // pate plutot que sur l'article.
        d.put(BARCODE_ENABLED, "false");
        d.put(BARCODE_AUTO_ADD, "true");
        d.put(BARCODE_UNKNOWN_ASK, "false");
        d.put(STOCK_MODE, "partiel");
        d.put(STOCK_RUPTURE, "refuser");
        d.put(STOCK_ENTREE, "libre");
        return d;
    }

    @Transactional(readOnly = true)
    public Map<String, String> all() {
        Map<String, String> m = defaults();
        repo.findAll().forEach(s -> m.put(s.getKey(), s.getValue()));
        return m;
    }

    @Transactional(readOnly = true)
    public String get(String key) { return all().get(key); }

    public boolean getBoolean(String key) { return "true".equalsIgnoreCase(get(key)); }
    public BigDecimal getDecimal(String key, BigDecimal def) {
        try { return new BigDecimal(get(key)); } catch (Exception e) { return def; }
    }

    @Transactional
    public Map<String, String> update(Map<String, String> values) {
        verifierNumerotation(values);
        StringBuilder changed = new StringBuilder();
        values.forEach((k, v) -> {
            AppSetting s = repo.findById(k).orElseGet(() -> { AppSetting n = new AppSetting(); n.setKey(k); return n; });
            s.setValue(v);
            s.setUpdatedAt(OffsetDateTime.now());
            repo.save(s);
            if (SENSITIVE.contains(k)) changed.append(k).append('=').append(v).append("; ");
        });
        audit.log("SETTINGS_UPDATE", "Setting", null, changed.length() > 0 ? changed.toString() : values.keySet().toString());
        return all();
    }

    /**
     * Un reglage de numerotation ne s'enregistre pas s'il fabrique des doublons.
     *
     * On juge le reglage COMPLET, celui qui sera en vigueur apres coup : l'ecran peut
     * n'envoyer qu'une case cochee, et c'est le melange avec ce qui est deja enregistre
     * qui compte. Refuser ici plutot que sur le ticket : une numerotation fautive ne se
     * voit qu'a l'encaissement, quand la contrainte d'unicite rejette la vente devant
     * le client.
     */
    private void verifierNumerotation(Map<String, String> values) {
        if (values.keySet().stream().noneMatch(NUMEROTATION::contains)) return;
        Map<String, String> apres = all();
        apres.putAll(values);
        List<String> soucis = TicketNumberService.problemes(TicketNumberService.Reglage.of(
                apres.get(TICKET_PATTERN), apres.get(TICKET_RESET_PERIOD),
                "true".equalsIgnoreCase(apres.get(TICKET_PER_POS)),
                "true".equalsIgnoreCase(apres.get(TICKET_PER_REGISTER)),
                apres.get(TICKET_DISPLAY_PATTERN)));
        if (!soucis.isEmpty()) throw new BusinessException(String.join(" ", soucis));
    }
}
