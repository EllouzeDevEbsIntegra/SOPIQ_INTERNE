package com.poscaisse.plateforme.repository;

import com.poscaisse.plateforme.domain.EditeurUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EditeurUserRepo extends JpaRepository<EditeurUser, Long> {
    Optional<EditeurUser> findByUsernameIgnoreCase(String username);
    List<EditeurUser> findAllByOrderByFullNameAsc();
}
