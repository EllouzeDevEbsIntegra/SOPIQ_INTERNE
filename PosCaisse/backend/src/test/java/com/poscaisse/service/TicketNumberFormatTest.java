package com.poscaisse.service;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class TicketNumberFormatTest {
    private final Map<String, Long> counters = new HashMap<>();
    private long next(String key) { long v = counters.getOrDefault(key, 1L); counters.put(key, v + 1); return v; }

    @Test void simpleSequence() {
        assertThat(TicketNumberService.format("{SEQ:6}", "PV01", "C01", this::next)).isEqualTo("000001");
        assertThat(TicketNumberService.format("{SEQ:6}", "PV01", "C01", this::next)).isEqualTo("000002");
    }

    @Test void posAndYearPattern() {
        int year = LocalDate.now(ZoneId.of("Africa/Tunis")).getYear();
        assertThat(TicketNumberService.format("{POS}-{YYYY}-{SEQ:6}", "PV01", "C01", this::next)).isEqualTo("PV01-" + year + "-000001");
        assertThat(TicketNumberService.format("{POS}-{YYYY}-{SEQ:6}", "PV02", "C01", this::next)).isEqualTo("PV02-" + year + "-000001"); // separate scope per prefix
        assertThat(TicketNumberService.format("{POS}-{YYYY}-{SEQ:6}", "PV01", "C01", this::next)).isEqualTo("PV01-" + year + "-000002");
    }

    @Test void registerAndWidthVariants() {
        assertThat(TicketNumberService.format("{REG}/{SEQ:4}", "PV01", "C02", this::next)).isEqualTo("C02/0001");
        assertThat(TicketNumberService.format("T{SEQ}", "", "", this::next)).isEqualTo("T000001");
    }
}
