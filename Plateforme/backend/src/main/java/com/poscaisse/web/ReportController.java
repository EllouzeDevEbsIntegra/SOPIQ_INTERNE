package com.poscaisse.web;

import com.poscaisse.reports.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

@RestController @RequestMapping("/api/reports") @RequiredArgsConstructor
@PreAuthorize("hasAuthority('REPORTS_VIEW')")
public class ReportController {
    private final ReportService reports;

    private static OffsetDateTime[] range(LocalDate from, LocalDate to) {
        LocalDate f = from == null ? LocalDate.now(ReportService.TZ) : from;
        LocalDate t = to == null ? f : to;
        return new OffsetDateTime[]{ReportService.startOf(f), ReportService.startOf(t.plusDays(1))};
    }

    @GetMapping("/dashboard")
    public Map<String, Object> dashboard(@RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
                                         @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
                                         @RequestParam(required = false) Long posId, @RequestParam(required = false) Long registerId,
                                         @RequestParam(required = false) Long cashierId) {
        OffsetDateTime[] r = range(from, to);
        return reports.dashboard(r[0], r[1], posId, registerId, cashierId);
    }

    @GetMapping("/{type}")
    public List<Map<String, Object>> report(@PathVariable String type,
                                            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
                                            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
                                            @RequestParam(required = false) Long posId, @RequestParam(required = false) Long registerId,
                                            @RequestParam(required = false) Long cashierId) {
        OffsetDateTime[] r = range(from, to);
        return reports.report(type, r[0], r[1], posId, registerId, cashierId);
    }

    @GetMapping(value = "/{type}/csv", produces = "text/csv")
    public ResponseEntity<byte[]> csv(@PathVariable String type,
                                     @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
                                     @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
                                     @RequestParam(required = false) Long posId, @RequestParam(required = false) Long registerId,
                                     @RequestParam(required = false) Long cashierId) {
        OffsetDateTime[] r = range(from, to);
        String csv = ReportService.toCsv(reports.report(type, r[0], r[1], posId, registerId, cashierId));
        return ResponseEntity.ok().header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=rapport-" + type + ".csv")
                .contentType(MediaType.parseMediaType("text/csv;charset=UTF-8")).body(csv.getBytes(StandardCharsets.UTF_8));
    }
}
