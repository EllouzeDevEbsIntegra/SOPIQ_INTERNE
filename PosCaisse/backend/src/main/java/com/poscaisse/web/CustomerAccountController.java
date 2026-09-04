package com.poscaisse.web;

import com.poscaisse.dto.CustomerAccountDtos.*;
import com.poscaisse.service.CustomerAccountService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

/** Comptes clients : soldes, relevés et règlements. */
@RestController @RequestMapping("/api/customer-accounts") @RequiredArgsConstructor
@PreAuthorize("hasAuthority('CUSTOMER_CREDIT')")
public class CustomerAccountController {
    private final CustomerAccountService accounts;

    @GetMapping
    public List<CustomerBalanceDto> balances(@RequestParam(defaultValue = "false") boolean withDebtOnly) {
        return accounts.balances(withDebtOnly);
    }

    @GetMapping("/{customerId}")
    public StatementDto statement(@PathVariable Long customerId,
                                  @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime from,
                                  @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime to) {
        return accounts.statement(customerId, from, to);
    }

    @PostMapping("/payments")
    public StatementPaymentDto pay(@Valid @RequestBody CustomerPaymentRequest r) { return accounts.pay(r); }

    @DeleteMapping("/payments/{id}")
    public Map<String, Boolean> delete(@PathVariable Long id) { accounts.deletePayment(id); return Map.of("ok", true); }
}
