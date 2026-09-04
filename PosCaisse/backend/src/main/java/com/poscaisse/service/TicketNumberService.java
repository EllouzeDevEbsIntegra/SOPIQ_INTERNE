package com.poscaisse.service;

import com.poscaisse.domain.DocumentSequence;
import com.poscaisse.domain.Enums;
import com.poscaisse.domain.PointOfSale;
import com.poscaisse.repository.SequenceRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Generates unique ticket numbers from a configurable pattern, e.g. "{POS}-{YYYY}-{SEQ:6}".
 * The sequence row is locked (SELECT ... FOR UPDATE) so concurrent registers never produce duplicates;
 * a UNIQUE constraint on sale_order.ticket_number is the final safety net.
 */
@Service @RequiredArgsConstructor
public class TicketNumberService {
    private static final Pattern SEQ = Pattern.compile("\\{SEQ(?::(\\d+))?}");
    private final SequenceRepo sequenceRepo;
    private final SettingsService settings;

    @Transactional(propagation = Propagation.MANDATORY)
    public String next(PointOfSale pos, String registerCode) {
        String pattern = settings.get(SettingsService.TICKET_PATTERN);
        if (pattern == null || !pattern.contains("{SEQ")) pattern = "{SEQ:6}";
        return format(pattern, pos == null ? "" : pos.getCode(), registerCode, key -> {
            DocumentSequence seq = sequenceRepo.lockByKey(key).orElseGet(() -> {
                DocumentSequence s = new DocumentSequence();
                s.setScopeKey(key);
                s.setNextValue(1);
                return sequenceRepo.saveAndFlush(s);
            });
            long v = seq.getNextValue();
            seq.setNextValue(v + 1);
            sequenceRepo.save(seq);
            return v;
        });
    }

    /**
     * Numero de reglement de compte, sur une sequence distincte de celle des tickets :
     * melanger les deux ferait des trous dans la numerotation des ventes. Clients et
     * livreurs ont chacun leur serie, pour que deux comptes ne se renvoient pas le
     * meme numero de piece.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public String nextAccountPayment(Enums.AccountParty party) {
        boolean courier = party == Enums.AccountParty.COURIER;
        LocalDate today = LocalDate.now(ZoneId.of("Africa/Tunis"));
        String scopeKey = (courier ? "COURIER_PAYMENT:" : "CUSTOMER_PAYMENT:") + today.getYear();
        DocumentSequence seq = sequenceRepo.lockByKey(scopeKey).orElseGet(() -> {
            DocumentSequence s = new DocumentSequence();
            s.setScopeKey(scopeKey);
            s.setNextValue(1);
            return sequenceRepo.saveAndFlush(s);
        });
        long v = seq.getNextValue();
        seq.setNextValue(v + 1);
        sequenceRepo.save(seq);
        return String.format(courier ? "RLV-%d-%06d" : "REG-%d-%06d", today.getYear(), v);
    }

    public interface SeqSource { long next(String scopeKey); }

    public static String format(String pattern, String posCode, String registerCode, SeqSource source) {
        LocalDate today = LocalDate.now(ZoneId.of("Africa/Tunis"));
        String resolved = pattern
                .replace("{POS}", posCode == null ? "" : posCode)
                .replace("{REG}", registerCode == null ? "" : registerCode)
                .replace("{YYYY}", String.valueOf(today.getYear()))
                .replace("{YY}", String.format("%02d", today.getYear() % 100))
                .replace("{MM}", String.format("%02d", today.getMonthValue()))
                .replace("{DD}", String.format("%02d", today.getDayOfMonth()));
        Matcher m = SEQ.matcher(resolved);
        if (!m.find()) return resolved;
        int width = m.group(1) == null ? 6 : Integer.parseInt(m.group(1));
        String scopeKey = "TICKET:" + resolved.replace(m.group(0), "#");
        long value = source.next(scopeKey);
        String num = String.format("%0" + width + "d", value);
        return resolved.substring(0, m.start()) + num + resolved.substring(m.end());
    }
}
