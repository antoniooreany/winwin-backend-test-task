package com.winwintravel.authapi.audit.dto;

import com.winwintravel.authapi.audit.AuthAuditAction;

import java.time.OffsetDateTime;

public record AuthAuditLogItemResponse(
        String email,
        AuthAuditAction action,
        boolean success,
        OffsetDateTime createdAt
) {
}
