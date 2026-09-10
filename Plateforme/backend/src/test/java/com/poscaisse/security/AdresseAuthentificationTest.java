package com.poscaisse.security;

import com.poscaisse.audit.AuditService;
import com.poscaisse.dto.AuthDtos.PinLoginRequest;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.SessionRepo;
import com.poscaisse.repository.UserRepo;
import com.poscaisse.service.AuthService;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;

class AdresseAuthentificationTest {
    private final MockHttpServletRequest requete = new MockHttpServletRequest();
    private final AuthService auth = new AuthService(mock(UserRepo.class), mock(SessionRepo.class),
            mock(PasswordEncoder.class), mock(JwtService.class), mock(AuditService.class),
            mock(CurrentUser.class), new AntiForceBrute(), requete);

    private void essai(String entete, String code) {
        requete.removeHeader("X-Forwarded-For");
        requete.addHeader("X-Forwarded-For", entete);
        assertThatThrownBy(() -> auth.loginWithPin(new PinLoginRequest(7L, "0000")))
                .isInstanceOfSatisfying(BusinessException.class, erreur ->
                        org.assertj.core.api.Assertions.assertThat(erreur.getCode()).isEqualTo(code));
    }

    @Test void uneAdresseInjecteeAvantCelleAjouteeParNginxNeChangePasLeCompteur() {
        requete.setRemoteAddr("127.0.0.1");
        for (int i = 0; i < 4; i++) essai("198.51.100." + i + ", 203.0.113.8", "BAD_PIN");
        essai("198.51.100.99, 203.0.113.8", "TROP_D_ESSAIS");
    }

    @Test void unAppelDirectNePeutPasChoisirSonAdresseParEntete() {
        requete.setRemoteAddr("203.0.113.8");
        for (int i = 0; i < 4; i++) essai("198.51.100." + i, "BAD_PIN");
        essai("198.51.100.99", "TROP_D_ESSAIS");
    }

    @Test void leBlocageDunPosteNeBloquePasUnAutrePoste() {
        requete.setRemoteAddr("127.0.0.1");
        for (int i = 0; i < 4; i++) essai("203.0.113.8", "BAD_PIN");
        essai("203.0.113.8", "TROP_D_ESSAIS");
        essai("203.0.113.9", "BAD_PIN");
    }
}
