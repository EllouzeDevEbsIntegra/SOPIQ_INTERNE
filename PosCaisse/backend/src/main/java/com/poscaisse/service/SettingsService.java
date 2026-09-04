package com.poscaisse.service;

import com.poscaisse.audit.AuditService;
import com.poscaisse.domain.AppSetting;
import com.poscaisse.repository.SettingRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

@Service @RequiredArgsConstructor
public class SettingsService {
    public static final String TICKET_PATTERN = "ticket.pattern";
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

    private static final Set<String> SENSITIVE = Set.of(TICKET_PATTERN, TAX_ENABLED, DISCOUNT_HIGH_THRESHOLD);

    private final SettingRepo repo;
    private final AuditService audit;

    public static Map<String, String> defaults() {
        Map<String, String> d = new LinkedHashMap<>();
        d.put(TICKET_PATTERN, "{POS}-{YYYY}-{SEQ:6}");
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
}
