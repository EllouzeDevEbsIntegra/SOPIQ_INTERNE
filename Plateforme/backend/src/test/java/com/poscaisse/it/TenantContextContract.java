package com.poscaisse.it;

import com.poscaisse.BaseDeTest;
import com.poscaisse.repository.ProductRepo;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Contrat de la cible « une application, N bases ».
 *
 * Il se lance explicitement avec le profil Maven audit-multitenant-contract. Tant que
 * l'aiguillage n'est pas construit, il doit rester rouge : une requête part actuellement
 * vers la source de données fixe sans exiger de client.
 */
@SpringBootTest
public class TenantContextContract {
    @Autowired ProductRepo produits;

    @DynamicPropertySource
    static void base(DynamicPropertyRegistry r) {
        BaseDeTest.neuve(r, "poscaisse_audit_absence_tenant");
    }

    @Test
    void uneRequeteSansContexteClientEchoueBruyamment() {
        assertThatThrownBy(() -> produits.count())
                .hasMessageContaining("Aucun client dans le contexte de la requête");
    }
}
