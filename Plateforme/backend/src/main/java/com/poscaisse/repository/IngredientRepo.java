package com.poscaisse.repository;

import com.poscaisse.domain.Ingredient;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface IngredientRepo extends JpaRepository<Ingredient, Long> {
    List<Ingredient> findAllByOrderBySortOrderAscIdAsc();
    List<Ingredient> findByActiveTrueOrderBySortOrderAscIdAsc();
    Optional<Ingredient> findByNameIgnoreCase(String name);
}
