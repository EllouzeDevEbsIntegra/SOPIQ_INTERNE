package com.poscaisse.plateforme;

import com.poscaisse.plateforme.domain.Abonnement;
import com.poscaisse.plateforme.domain.Client;
import com.poscaisse.plateforme.repository.AbonnementRepo;
import com.poscaisse.plateforme.service.AdressesClients;
import com.poscaisse.plateforme.service.ErreurMetier;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * L'ADRESSE QUE LE COMMERCANT TAPERA TOUS LES MATINS.
 *
 * Ce qui se joue ici n'a l'air de rien - fabriquer un nom - et porte pourtant deux
 * promesses qu'on ne peut pas reprendre apres coup. La premiere : cette adresse est ecrite
 * sur le comptoir du client et dans son navigateur, elle ne changera plus. La seconde :
 * elle n'appartient qu'a lui, sans quoi un commercant ouvrirait la caisse d'un autre.
 *
 * Le nom finit aussi dans un nom de fichier, une unite systemd et une directive nginx.
 * Les scenarios qui suivent verifient donc autant ce qu'il PEUT contenir que ce qu'il ne
 * peut pas.
 */
class AdressesClientsTest {

    private AbonnementRepo abonnements;
    private AdressesClients adresses;
    private final List<Abonnement> enBase = new ArrayList<>();

    @BeforeEach
    void poser() {
        enBase.clear();
        abonnements = mock(AbonnementRepo.class);
        when(abonnements.findAll()).thenReturn(enBase);
        adresses = new AdressesClients(abonnements);
        ReflectionTestUtils.setField(adresses, "domaine", "pos.ebs-integra.com");
        ReflectionTestUtils.setField(adresses, "portMin", 8101);
        ReflectionTestUtils.setField(adresses, "portMax", 8103);
    }

    @Test
    @DisplayName("l'enseigne devient une adresse lisible au téléphone")
    void depuisLEnseigne() {
        assertThat(adresses.sousDomaineLibre(client("CLI0001", "Number One"))).isEqualTo("number-one");
        assertThat(adresses.sousDomaineLibre(client("CLI0002", "CAFÉ DES DÉLICES"))).isEqualTo("cafe-des-delices");
        assertThat(adresses.sousDomaineLibre(client("CLI0003", "Pâtisserie  d'Alia !"))).isEqualTo("patisserie-d-alia");
    }

    /**
     * Les accents sont DECOMPOSES puis leurs marques retirees, et non remplaces lettre a
     * lettre : une table de correspondance oublie toujours un caractere, et celui qu'elle
     * oublie disparaitrait du nom au lieu d'y laisser sa lettre de base.
     */
    @Test
    @DisplayName("une enseigne qui ne donne rien retombe sur le code client")
    void repliSurLeCode() {
        assertThat(adresses.sousDomaineLibre(client("CLI0009", "مقهى النور"))).isEqualTo("cli0009");
    }

    @Test
    @DisplayName("deux commerces à la même enseigne obtiennent deux adresses")
    void memeEnseigneDeuxAdresses() {
        enBase.add(abonnement("number-one", 8101));
        assertThat(adresses.sousDomaineLibre(client("CLI0002", "Number One"))).isEqualTo("number-one-2");
    }

    /**
     * << demo-resto >> appartient a la demonstration RESTO depuis V3. Un client qui
     * l'obtiendrait volerait son adresse, et son vhost prendrait la place de l'autre.
     */
    @Test
    @DisplayName("les noms réservés ne sont donnés à personne")
    void nomsReserves() {
        /*
            << demo-resto >> et sa raison sociale << demo-resto-sarl >> commencent tous deux
            par le prefixe des demonstrations : aucune des deux sources n'est utilisable, et
            le client recoit son code. Une adresse un peu terne vaut mieux qu'une adresse
            qu'on prendrait pour une demo - ou pire, qui prendrait la place de l'une d'elles.
        */
        assertThat(adresses.sousDomaineLibre(client("CLI0004", "Demo Resto"))).isEqualTo("cli0004");
        assertThat(adresses.sousDomaineLibre(client("CLI0005", "POS"))).isEqualTo("pos-2");
        assertThat(adresses.sousDomaineLibre(client("CLI0006", "Admin"))).isEqualTo("admin-2");
    }

    @Test
    @DisplayName("le premier port libre, y compris celui qu'un client résilié a rendu")
    void premierPortLibre() {
        assertThat(adresses.portLibre()).isEqualTo(8101);

        enBase.add(abonnement("un", 8101));
        enBase.add(abonnement("trois", 8103));
        assertThat(adresses.portLibre()).as("le trou de 8102 est repris").isEqualTo(8102);
    }

    /**
     * Le refus doit etre net et dire quoi faire : un port silencieusement reattribue
     * donnerait une seconde caisse qui ne demarre pas, avec un << Address already in
     * use >> dans un journal que personne ne lit.
     */
    @Test
    @DisplayName("plus de port libre : on refuse en disant lequel des deux réglages élargir")
    void plusDePortLibre() {
        enBase.add(abonnement("un", 8101));
        enBase.add(abonnement("deux", 8102));
        enBase.add(abonnement("trois", 8103));
        assertThatThrownBy(() -> adresses.portLibre())
                .isInstanceOf(ErreurMetier.class)
                .hasMessageContaining("port-max");
    }

    @Test
    @DisplayName("la forme juridique est retirée du nom, et ne reste jamais seule")
    void formeJuridique() {
        Client sansEnseigne = client("CLI0007", "Number One");
        sansEnseigne.setEnseigne(null);
        sansEnseigne.setRaisonSociale("Number One SARL");
        assertThat(adresses.sousDomaineLibre(sansEnseigne)).isEqualTo("number-one");
    }

    @Test
    @DisplayName("l'adresse complète est celle que le client tapera")
    void adresseComplete() {
        assertThat(adresses.adresse("number-one")).isEqualTo("https://number-one.pos.ebs-integra.com");
    }

    // ------------------------------------------------------------------ mecanique

    private static Client client(String code, String enseigne) {
        Client c = new Client();
        c.setCode(code);
        c.setRaisonSociale(enseigne + " SARL");
        c.setEnseigne(enseigne);
        return c;
    }

    private static Abonnement abonnement(String sousDomaine, int port) {
        Abonnement a = new Abonnement();
        a.setSousDomaine(sousDomaine);
        a.setPort(port);
        return a;
    }
}
