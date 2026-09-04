package com.poscaisse.web;

import com.poscaisse.dto.AccountDtos.*;
import com.poscaisse.service.AccountService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

/** Comptes à crédit : soldes, relevés et règlements. {party} vaut CUSTOMER ou COURIER. */
@RestController @RequestMapping("/api/accounts/{party}") @RequiredArgsConstructor
@PreAuthorize("hasAuthority('CUSTOMER_CREDIT')")
public class AccountController {
    private final AccountService accounts;

    @GetMapping
    public List<AccountBalanceDto> balances(@PathVariable String party,
                                            @RequestParam(defaultValue = "false") boolean withDebtOnly) {
        return accounts.balances(AccountService.party(party), withDebtOnly);
    }

    @GetMapping("/{partyId}")
    public StatementDto statement(@PathVariable String party, @PathVariable Long partyId,
                                  @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
                                  @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to) {
        return accounts.statement(AccountService.party(party), partyId, from, to);
    }

    @PostMapping("/payments")
    public StatementPaymentDto pay(@PathVariable String party, @Valid @RequestBody AccountPaymentRequest r) {
        return accounts.pay(AccountService.party(party), r);
    }

    @DeleteMapping("/payments/{id}")
    public Map<String, Boolean> delete(@PathVariable String party, @PathVariable Long id) {
        accounts.deletePayment(id);
        return Map.of("ok", true);
    }
}
