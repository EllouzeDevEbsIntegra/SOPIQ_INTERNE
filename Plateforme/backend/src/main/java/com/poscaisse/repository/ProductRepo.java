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
    List<Product> findByStockManagedTrueAndActiveTrueOrderByNameAsc();
    List<Product> findByActiveTrueOrderBySortOrderAscNameAsc();
    long countByCategoryId(Long categoryId);
}
