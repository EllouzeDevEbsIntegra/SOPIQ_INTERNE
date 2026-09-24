package com.poscaisse.repository;

import com.poscaisse.domain.*;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ProductRepo extends JpaRepository<Product, Long> {
    List<Product> findAllByOrderBySortOrderAscNameAsc();
    Optional<Product> findByCode(String code);

    /**
     * L'article que le scanner vient de lire.
     *
     * Le code est cherche tel quel : un code-barres n'a ni casse ni accent, et le
     * comparer autrement reviendrait a accepter deux articles pour un meme scan.
     */
    Optional<Product> findByBarcode(String barcode);

    /**
     * Les articles qui portent DEJA l'un de ces codes, en principal ou en secondaire.
     *
     * POURQUOI UNE REQUETE NATIVE. Le meme code chez deux articles rend le scan ambigu :
     * la douchette en choisirait un, toujours le meme, et l'autre serait invendable sans
     * que rien ne le dise. La verification doit donc couvrir les DEUX colonnes d'un coup,
     * et croiser une liste avec une liste - ce que JPQL ne sait pas exprimer sur un texte
     * decoupe.
     *
     * {@code codes} est la liste entiere separee par des espaces, passee telle quelle :
     * un seul parametre, pas de tableau a lier, et l'operateur && utilise l'index GIN de
     * la V19.
     */
    @Query(value = """
            SELECT * FROM product p
             WHERE (:id IS NULL OR p.id <> :id)
               AND ( p.barcode = ANY (string_to_array(:codes, ' '))
                  OR string_to_array(p.barcodes_secondaires, ' ') && string_to_array(:codes, ' ') )
            """, nativeQuery = true)
    List<Product> portantUnDeCesCodes(@Param("codes") String codes, @Param("id") Long id);
    List<Product> findByStockManagedTrueAndActiveTrueOrderByNameAsc();
    List<Product> findByActiveTrueOrderBySortOrderAscNameAsc();
    long countByCategoryId(Long categoryId);
}
