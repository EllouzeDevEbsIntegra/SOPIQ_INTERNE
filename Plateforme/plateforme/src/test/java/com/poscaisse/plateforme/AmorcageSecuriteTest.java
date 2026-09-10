package com.poscaisse.plateforme;

import com.poscaisse.plateforme.repository.EditeurUserRepo;
import com.poscaisse.plateforme.service.Amorcage;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(OutputCaptureExtension.class)
class AmorcageSecuriteTest {
    private final EditeurUserRepo users = mock(EditeurUserRepo.class);
    private final PasswordEncoder encodeur = mock(PasswordEncoder.class);
    private final ApplicationContextRunner contexte = new ApplicationContextRunner()
            .withUserConfiguration(Amorcage.class)
            .withBean(EditeurUserRepo.class, () -> users)
            .withBean(PasswordEncoder.class, () -> encodeur);

    @Test void aucunCompteAdministrateurSansSecretExplicite() {
        contexte.run(c -> {
            assertThatThrownBy(() -> c.getBean(ApplicationRunner.class).run(new DefaultApplicationArguments()))
                    .isInstanceOf(IllegalStateException.class).hasMessageContaining("PLATEFORME_ADMIN_PASSWORD");
            verify(users, never()).save(any());
        });
    }

    @Test void seulLeSecretConfigureEstUtiliseEtIlNePartPasDansLesJournaux(CapturedOutput sortie) {
        String secret = "Secret-initial-audit-2026";
        contexte.withPropertyValues("plateforme.admin-password=" + secret).run(c -> {
            c.getBean(ApplicationRunner.class).run(new DefaultApplicationArguments());
            verify(encodeur).encode(secret);
            verify(users).save(argThat(u -> u.getUsername().equals("admin")));
        });
        assertThat(sortie.getAll()).doesNotContain(secret).doesNotContain("plateforme123");
    }

    @Test void unCompteExistantNeDemandePasLeSecretDePremiereInstallation() {
        when(users.count()).thenReturn(1L);
        contexte.run(c -> c.getBean(ApplicationRunner.class).run(new DefaultApplicationArguments()));
        verify(users, never()).save(any());
    }
}
