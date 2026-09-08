package com.poscaisse.web;

import com.poscaisse.dto.RegisterDtos.*;
import com.poscaisse.service.ClosureService;
import com.poscaisse.service.JournalService;
import com.poscaisse.service.RegisterSessionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;

@RestController @RequestMapping("/api") @RequiredArgsConstructor
public class RegisterController {
    private final RegisterSessionService sessions;
    private final JournalService journal;
    private final ClosureService closures;

    @PreAuthorize("hasAuthority('REVENUE_VIEW')")
    @GetMapping("/register-sessions")
    public List<SessionDto> sessions(@RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
                                     @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to) { return sessions.search(from, to); }
    @GetMapping("/register-sessions/{id}") public SessionDto session(@PathVariable Long id) { return sessions.get(id); }
    @GetMapping("/register-sessions/{id}/summary") public SessionSummary summary(@PathVariable Long id) { return sessions.summary(id); }
    @GetMapping("/register-sessions/{id}/movements") public List<CashMovementDto> movements(@PathVariable Long id) { return sessions.movements(id); }

    @GetMapping("/journal")
    public List<JournalDto> journal(@RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
                                    @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to,
                                    @RequestParam(required = false) Long posId, @RequestParam(required = false) Long registerId,
                                    @RequestParam(required = false) Long userId, @RequestParam(required = false) Long sessionId,
                                    @RequestParam(required = false) String event, @RequestParam(defaultValue = "500") int limit) {
        return journal.search(from, to, posId, registerId, userId, sessionId, event, limit);
    }

    @PreAuthorize("hasAuthority('DAILY_CLOSE')") @GetMapping("/closures") public List<DailyClosureDto> closures() { return closures.list(); }
    @PreAuthorize("hasAuthority('DAILY_CLOSE')") @GetMapping("/closures/preview")
    public DailyPreview preview(@RequestParam Long posId, @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) { return closures.preview(posId, date); }
    @PreAuthorize("hasAuthority('DAILY_CLOSE')") @PostMapping("/closures") public DailyClosureDto close(@Valid @RequestBody DailyClosureRequest r) { return closures.close(r); }
}
