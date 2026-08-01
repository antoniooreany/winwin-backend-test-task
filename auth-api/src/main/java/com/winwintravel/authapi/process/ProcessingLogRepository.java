package com.winwintravel.authapi.process;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProcessingLogRepository extends JpaRepository<ProcessingLog, Long> {

    Page<ProcessingLog> findByUser_EmailOrderByCreatedAtDesc(String userEmail, Pageable pageable);
}
