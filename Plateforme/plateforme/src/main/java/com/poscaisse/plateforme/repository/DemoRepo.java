package com.poscaisse.plateforme.repository;

import com.poscaisse.plateforme.domain.Demo;
import com.poscaisse.plateforme.domain.Enums;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DemoRepo extends JpaRepository<Demo, Enums.Module> {
    List<Demo> findByAllumeeTrue();
    List<Demo> findAllByOrderByModuleAsc();
}
