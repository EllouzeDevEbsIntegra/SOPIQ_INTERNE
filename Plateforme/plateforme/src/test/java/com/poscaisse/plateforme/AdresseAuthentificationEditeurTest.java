package com.poscaisse.plateforme;

import com.poscaisse.plateforme.dto.Dtos.ConnexionRequest;
import com.poscaisse.plateforme.repository.EditeurUserRepo;
import com.poscaisse.plateforme.security.*;
import com.poscaisse.plateforme.service.*;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;

class AdresseAuthentificationEditeurTest {
    private final MockHttpServletRequest requete = new MockHttpServletRequest();
    private final AuthService auth = new AuthService(mock(EditeurUserRepo.class), mock(PasswordEncoder.class),
            mock(JwtService.class), new AntiForceBrute(), mock(JournalService.class),
            mock(UtilisateurCourant.class), requete);

    private void essai(String entete, String identifiant, String code) {
        requete.removeHeader("X-Forwarded-For");
        requete.addHeader("X-Forwarded-For", entete);
        assertThatThrownBy(() -> auth.connexion(new ConnexionRequest(identifiant, "faux")))
                .isInstanceOfSatisfying(ErreurMetier.class, erreur ->
                        org.assertj.core.api.Assertions.assertThat(erreur.getCode()).isEqualTo(code));
    }

    @Test void changerLaPremiereAdresseDeclareeNeContournePasLeRalentisseur() {
        requete.setRemoteAddr("127.0.0.1");
        for (int i = 0; i < 4; i++) essai("198.51.100." + i + ", 203.0.113.8", "compte" + i, "IDENTIFIANTS");
        essai("198.51.100.99, 203.0.113.8", "compte-final", "TROP_D_ESSAIS");
    }

    @Test void unAccesDirectNeFaitPasConfianceALEntete() {
        requete.setRemoteAddr("203.0.113.8");
        for (int i = 0; i < 4; i++) essai("198.51.100." + i, "compte" + i, "IDENTIFIANTS");
        essai("198.51.100.99", "compte-final", "TROP_D_ESSAIS");
    }
}
