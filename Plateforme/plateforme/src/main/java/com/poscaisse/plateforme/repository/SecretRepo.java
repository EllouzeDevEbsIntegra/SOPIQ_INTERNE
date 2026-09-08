package com.poscaisse.plateforme.repository;

import com.poscaisse.plateforme.domain.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface SecretRepo extends JpaRepository<AppSecret, String> {
    @Modifying @Transactional
    @Query(value = "insert into app_secret(key, value) values (:k, :v) on conflict (key) do nothing", nativeQuery = true)
    int poserSiAbsent(@Param("k") String k, @Param("v") String v);
}
