package com.winwintravel.authapi.audit.dto;

import java.util.List;

public record AuthAuditLogResponse(
        List<AuthAuditLogItemResponse> items
) {
}
