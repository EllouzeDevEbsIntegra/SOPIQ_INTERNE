package com.poscaisse.repository;

import com.poscaisse.domain.Courier;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CourierRepo extends JpaRepository<Courier, Long> {
    @Query("select c from Courier c where lower(c.name) like lower(concat('%', :q, '%')) or c.phone like concat('%', :q, '%') order by c.name")
    List<Courier> search(@Param("q") String q);
    List<Courier> findAllByOrderByNameAsc();
    List<Courier> findByActiveTrueOrderByNameAsc();
}
