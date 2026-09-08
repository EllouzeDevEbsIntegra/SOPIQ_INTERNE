package com.poscaisse.repository;

import com.poscaisse.domain.OrderLineModifier;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OrderLineModifierRepo extends JpaRepository<OrderLineModifier, Long> {
    long countByModifier_Group_Id(Long groupId);
}
