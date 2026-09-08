package com.poscaisse.repository;

import com.poscaisse.domain.AppSecret;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
public interface AppSecretRepo extends JpaRepository<AppSecret, String> {

    /**
     * Poser le secret s'il n'existe pas encore, et ne rien faire sinon.
     *
     * Deux instances qui demarrent ensemble tireraient chacune une cle au sort, et la
     * seconde ecraserait la premiere : les jetons deja signes deviendraient invalides sans
     * raison visible. C'est la base qui tranche, en une seule instruction.
     */
    @Modifying @Transactional
    @Query(value = "insert into app_secret(key, value) values (:k, :v) on conflict (key) do nothing", nativeQuery = true)
    int poserSiAbsent(@Param("k") String k, @Param("v") String v);
}
