package com.poscaisse.repository;

import com.poscaisse.domain.KitchenNote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface KitchenNoteRepo extends JpaRepository<KitchenNote, Long> {
    List<KitchenNote> findAllByOrderBySortOrderAscIdAsc();
    List<KitchenNote> findByActiveTrueOrderBySortOrderAscIdAsc();
}
