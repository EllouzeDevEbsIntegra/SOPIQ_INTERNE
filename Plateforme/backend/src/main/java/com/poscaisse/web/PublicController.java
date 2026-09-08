package com.poscaisse.web;

import com.poscaisse.domain.Company;
import com.poscaisse.repository.CompanyRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/** Informations affichables avant connexion (écran de login) : identité du commerce uniquement. */
@RestController @RequestMapping("/api/public") @RequiredArgsConstructor
public class PublicController {
    private final CompanyRepo companyRepo;

    @GetMapping("/branding")
    public Map<String, Object> branding() {
        Company c = companyRepo.findAll().stream().findFirst().orElse(null);
        if (c == null) return Map.of();
        Map<String, Object> m = new java.util.LinkedHashMap<>();
        m.put("name", c.getName());
        m.put("tradeName", c.getTradeName());
        m.put("logoData", c.getLogoData());
        return m;
    }
}
