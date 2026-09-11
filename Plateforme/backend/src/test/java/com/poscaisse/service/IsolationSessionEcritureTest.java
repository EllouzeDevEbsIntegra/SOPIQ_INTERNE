package com.poscaisse.service;

import com.poscaisse.domain.*;
import com.poscaisse.dto.RegisterDtos.CashMovementRequest;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.*;
import com.poscaisse.security.CurrentUser;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class IsolationSessionEcritureTest {
    @Mock SessionRepo sessions;
    @Mock RegisterRepo caisses;
    @Mock PaymentRepo paiements;
    @Mock RefundRepo remboursements;
    @Mock CashMovementRepo mouvements;
    @Mock OrderRepo commandes;
    @Mock CurrentUser courant;
    @Mock com.poscaisse.audit.AuditService audit;
    @Mock JournalService journal;
    @Mock SettingsService reglages;
    @Mock CompanyRepo societes;
    @Mock com.poscaisse.printing.ReceiptRenderer rendu;
    @Mock com.poscaisse.printing.PrintService impression;
    @InjectMocks RegisterSessionService service;

    private RegisterSession sessionEtrangere;

    @BeforeEach void preparer() {
        User proprietaire = new User(); proprietaire.setId(10L);
        User autre = new User(); autre.setId(20L);
        Register caisse = new Register(); caisse.setId(3L);
        sessionEtrangere = new RegisterSession(); sessionEtrangere.setId(7L);
        sessionEtrangere.setOpenedBy(proprietaire); sessionEtrangere.setRegister(caisse);
        when(courant.id()).thenReturn(autre.getId());
    }

    @Test void unCaissierNeVendPasDansLaSessionDUnCollegue() {
        when(sessions.findFirstByRegisterIdAndStatus(3L, Enums.SessionStatus.OPEN))
                .thenReturn(Optional.of(sessionEtrangere));
        assertThatThrownBy(() -> service.requireOpenSession(3L))
                .isInstanceOf(BusinessException.class).hasMessageContaining("n'est pas la vôtre");
    }

    @Test void unCaissierNeSortPasDArgentDeLaSessionDUnCollegue() {
        when(sessions.findById(7L)).thenReturn(Optional.of(sessionEtrangere));
        assertThatThrownBy(() -> service.addMovement(7L,
                new CashMovementRequest("OUT", "Course", BigDecimal.ONE, null)))
                .isInstanceOf(BusinessException.class).hasMessageContaining("n'est pas la vôtre");
        verify(mouvements, never()).save(any());
    }
}
