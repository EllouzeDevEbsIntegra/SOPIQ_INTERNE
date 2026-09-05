package com.poscaisse.repository;

import com.poscaisse.domain.VariantValue;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VariantValueRepo extends JpaRepository<VariantValue, Long> { }
