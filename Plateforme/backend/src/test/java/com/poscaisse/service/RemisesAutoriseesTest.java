package com.poscaisse.service;

import com.poscaisse.domain.*;
import com.poscaisse.dto.OrderDtos.*;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.ProductRepo;
import com.poscaisse.repository.RegisterRepo;
import com.poscaisse.security.CurrentUser;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RemisesAutoriseesTest {
    @Mock ProductRepo produits;
    @Mock RegisterRepo caisses;
    @Mock CurrentUser courant;
    @Mock SettingsService reglages;
    @Spy PricingService prix = new PricingService();
    @InjectMocks OrderService commandes;
    private final User caissier = new User();

    @BeforeEach void preparer() {
        Category categorie = new Category(); categorie.setId(1L);
        Product produit = new Product(); produit.setId(1L); produit.setName("Article"); produit.setCategory(categorie); produit.setPrice(new BigDecimal("100"));
        PointOfSale point = new PointOfSale(); point.setCompany(new Company());
        Register caisse = new Register(); caisse.setId(1L); caisse.setPointOfSale(point);
        when(caisses.findById(1L)).thenReturn(Optional.of(caisse));
        lenient().when(produits.findById(1L)).thenReturn(Optional.of(produit));
        when(courant.entity()).thenReturn(caissier);
        when(reglages.get(SettingsService.DEFAULT_SERVICE_MODE)).thenReturn("TAKEAWAY");
        when(reglages.get(SettingsService.SERVICE_MODES)).thenReturn("TAKEAWAY");
        lenient().when(reglages.getDecimal(SettingsService.DISCOUNT_HIGH_THRESHOLD, BigDecimal.TEN)).thenReturn(BigDecimal.TEN);
        lenient().when(courant.has(Permission.DISCOUNT_APPLY)).thenReturn(true);
        caissier.setMaxDiscountPercent(new BigDecimal("10"));
    }

    private PriceQuote devis(String pctCommande, String montantCommande, String pctLigne, String montantLigne, BigDecimal quantite) {
        CartLineRequest ligne = new CartLineRequest(1L, quantite, null, decimal(pctLigne), decimal(montantLigne), null, null, null, null);
        return commandes.quote(new CartRequest(null, 1L, null, null, null, null, null, null,
                decimal(pctCommande), decimal(montantCommande), List.of(ligne), null));
    }
    private BigDecimal decimal(String valeur) { return valeur == null ? null : new BigDecimal(valeur); }

    @Test void uneRemiseNegativeSurLeTicketEstRefusee() {
        assertThatThrownBy(() -> devis("-10", null, null, null, BigDecimal.ONE)).isInstanceOf(BusinessException.class).hasMessageContaining("Remise invalide");
    }
    @Test void uneRemiseNegativeSurLaLigneEstRefusee() {
        assertThatThrownBy(() -> devis(null, null, "-10", null, BigDecimal.ONE)).isInstanceOf(BusinessException.class).hasMessageContaining("Remise invalide");
    }
    @Test void unMontantDeRemiseNegatifEstRefuse() {
        assertThatThrownBy(() -> devis(null, "-1", null, null, BigDecimal.ONE)).isInstanceOf(BusinessException.class).hasMessageContaining("Remise invalide");
    }
    @Test void laRemiseEnDinarsDuTicketRespecteLePlafondPersonnel() {
        assertThatThrownBy(() -> devis(null, "50", null, null, BigDecimal.ONE)).isInstanceOf(BusinessException.class).hasMessageContaining("maximale autorisée");
    }
    @Test void laRemiseEnDinarsDeLaLigneRespecteLePlafondPersonnel() {
        assertThatThrownBy(() -> devis(null, null, null, "50", BigDecimal.ONE)).isInstanceOf(BusinessException.class).hasMessageContaining("maximale autorisée");
    }
    @Test void sansPlafondPersonnelLaRemiseEnDinarsExigeToujoursLeDroitManager() {
        caissier.setMaxDiscountPercent(null);
        assertThatThrownBy(() -> devis(null, "50", null, null, BigDecimal.ONE)).isInstanceOf(BusinessException.class).hasMessageContaining("manager");
    }
    @Test void uneRemiseEnDinarsAutoriseeConserveSonCalcul() {
        assertThat(devis(null, "5", null, null, BigDecimal.ONE).total()).isEqualByComparingTo("95.000");
    }
    @Test void uneQuantiteNulleEstRefusee() {
        assertThatThrownBy(() -> devis(null, null, null, null, null)).isInstanceOf(BusinessException.class).hasMessageContaining("Quantité invalide");
    }
    @Test void uneQuantiteZeroEstRefusee() {
        assertThatThrownBy(() -> devis(null, null, null, null, BigDecimal.ZERO)).isInstanceOf(BusinessException.class).hasMessageContaining("Quantité invalide");
    }
}
