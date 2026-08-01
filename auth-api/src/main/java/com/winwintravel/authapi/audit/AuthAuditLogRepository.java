package com.winwintravel.authapi.audit;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AuthAuditLogRepository extends JpaRepository<AuthAuditLog, Long> {
    List<AuthAuditLog> findByEmailOrderByCreatedAtDesc(String email);
}
