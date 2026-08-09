package com.winwintravel.authapi.audit;

import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AuthAuditLogService {

    private final AuthAuditLogRepository authAuditLogRepository;

    public AuthAuditLogService(AuthAuditLogRepository authAuditLogRepository) {
        this.authAuditLogRepository = authAuditLogRepository;
    }

    public void logLoginAttempt(String email, boolean success) {
        AuthAuditLog entry = new AuthAuditLog();
        entry.setEmail(email);
        entry.setAction(AuthAuditAction.LOGIN);
        entry.setSuccess(success);
        authAuditLogRepository.save(entry);
    }

    public List<AuthAuditLog> getAuditLogForUser(String email) {
        return authAuditLogRepository.findByEmailOrderByCreatedAtDesc(email);
    }
}
