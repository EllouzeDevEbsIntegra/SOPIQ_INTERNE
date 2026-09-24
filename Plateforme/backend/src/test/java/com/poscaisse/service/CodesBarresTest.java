package com.poscaisse.service;

import com.poscaisse.domain.Product;
import com.poscaisse.exception.BusinessException;
import com.poscaisse.repository.ProductRepo;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * PLUSIEURS CODES-BARRES POUR UN MEME ARTICLE.
 *
 * En superette, le meme produit arrive avec des EAN differents selon le fournisseur, le
 * format ou l'annee : l'export du premier client reel en comptait 885 pour 395 articles,
 * jusqu'a quatorze pour un seul. Un article qui ne passe pas a la douchette, c'est un
 * caissier qui cherche a la main devant une file qui attend.
 *
 * CE QUE CES SCENARIOS PROTEGENT, et qui ne se voit pas a l'oeil : qu'un code ne puisse
 * jamais appartenir a DEUX articles. La douchette en choisirait un, toujours le meme, et
 * l'autre deviendrait invendable sans que rien ne le signale - le genre de defaut qu'on
 * decouvre un samedi de affluence.
 */
class CodesBarresTest {

    @Test
    @DisplayName("les codes sont nettoyés : vides, espaces et doublons internes")
    void nettoyage() {
        assertThat(CodesBarres.nettoyer(List.of(" 6194 ", "", "6194", "  ", "7100")))
                .containsExactly("6194", "7100");
        assertThat(CodesBarres.joindre(List.of())).isNull();
        assertThat(CodesBarres.separer(null)).isEmpty();
        assertThat(CodesBarres.separer("6194 7100")).containsExactly("6194", "7100");
    }

    /**
     * Un export repete presque toujours le code principal dans la liste des autres. Le
     * garder aux deux endroits ferait croire a un doublon a la verification suivante, et
     * l'article se refuserait lui-meme.
     */
    @Test
    @DisplayName("le code principal ne se répète pas dans les secondaires")
    void principalRetireDesSecondaires() {
        ProductRepo repo = mock(ProductRepo.class);
        when(repo.portantUnDeCesCodes(anyString(), any())).thenReturn(List.of());
        Product p = new Product(); p.setName("OREO");

        CodesBarres.poser(p, "7100000000017", List.of("7100000000017", "6194008533630"), repo);

        assertThat(p.getBarcode()).isEqualTo("7100000000017");
        assertThat(CodesBarres.separer(p.getBarcodesSecondaires())).containsExactly("6194008533630");
    }

    @Test
    @DisplayName("un code déjà porté par un autre article est refusé, et l'article fautif est nommé")
    void doublonRefuse() {
        Product autre = new Product();
        autre.setName("RINGO POCKET");
        autre.setBarcodesSecondaires("6194008533630 6194008533975");

        ProductRepo repo = mock(ProductRepo.class);
        when(repo.portantUnDeCesCodes(anyString(), any())).thenReturn(List.of(autre));

        Product p = new Product(); p.setName("OREO");
        assertThatThrownBy(() -> CodesBarres.poser(p, "7100", List.of("6194008533975"), repo))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("6194008533975")
                .hasMessageContaining("RINGO POCKET");
    }

    /**
     * L'IMPORT NE S'ARRETE PAS, et c'est une regle differente de celle de la fiche article.
     * Une carte de quatre cents lignes venue d'un autre logiciel porte presque toujours un
     * code recopie deux fois : refuser tout l'import pour cela rendrait la reprise de
     * donnees impossible.
     */
    @Test
    @DisplayName("à l'import, le code en conflit est écarté et l'article entre quand même")
    void importTolerant() {
        Product autre = new Product();
        autre.setName("RINGO POCKET");
        autre.setBarcode("6194008533975");

        ProductRepo repo = mock(ProductRepo.class);
        when(repo.portantUnDeCesCodes(anyString(), any())).thenReturn(List.of(autre));

        Product p = new Product(); p.setName("OREO");
        List<String> avertissements = CodesBarres.poserTolerant(
                p, "7100", List.of("6194008533975", "6194008534002"), repo, true);

        assertThat(p.getBarcode()).as("son code principal est intact").isEqualTo("7100");
        assertThat(CodesBarres.separer(p.getBarcodesSecondaires()))
                .as("seul le code en conflit est écarté").containsExactly("6194008534002");
        assertThat(avertissements).singleElement()
                .asString().contains("6194008533975").contains("RINGO POCKET");
    }
}
