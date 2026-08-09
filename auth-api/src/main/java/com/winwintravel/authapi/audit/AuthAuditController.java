package com.winwintravel.authapi.audit;

import com.winwintravel.authapi.audit.dto.AuthAuditLogItemResponse;
import com.winwintravel.authapi.audit.dto.AuthAuditLogResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/auth/audit")
public class AuthAuditController {

    private final AuthAuditLogService authAuditLogService;

    public AuthAuditController(AuthAuditLogService authAuditLogService) {
        this.authAuditLogService = authAuditLogService;
    }

    @GetMapping
    public ResponseEntity<AuthAuditLogResponse> getAuditLog(Principal principal) {
        List<AuthAuditLogItemResponse> items = authAuditLogService.getAuditLogForUser(principal.getName())
                .stream()
                .map(entry -> new AuthAuditLogItemResponse(
                        entry.getEmail(),
                        entry.getAction(),
                        entry.isSuccess(),
                        entry.getCreatedAt()
                ))
                .toList();

        return ResponseEntity.ok(new AuthAuditLogResponse(items));
    }
}
