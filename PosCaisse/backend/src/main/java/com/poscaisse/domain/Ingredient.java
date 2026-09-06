package com.poscaisse.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.OffsetDateTime;

/**
 * Ingrédient composant le nom d'un article : « Omelette », « Thon », « Salami ».
 *
 * Il ne se vend pas et ne porte pas de prix — pour cela, ce sont les options
 * (ModifierGroup) qui s'appliquent. Il sert à composer un nom sans le retaper, et à
 * retrouver en caisse les articles qui le contiennent.
 */
@Entity @Table(name = "ingredient") @Getter @Setter
public class Ingredient {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    private String name;
    /** Nom du ticket : « Oml » pour Omlette. 42 colonnes de papier ne tiennent pas les noms longs. */
    private String shortName;
    private int sortOrder;
    private boolean active = true;
    private OffsetDateTime createdAt = OffsetDateTime.now();
}
