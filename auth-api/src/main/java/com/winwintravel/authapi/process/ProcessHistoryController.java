package com.winwintravel.authapi.process;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/process")
@Validated
public class ProcessHistoryController {

    private final ProcessingHistoryService processingHistoryService;

    public ProcessHistoryController(ProcessingHistoryService processingHistoryService) {
        this.processingHistoryService = processingHistoryService;
    }

    @GetMapping("/history")
    public ResponseEntity<ProcessingHistoryResponse> getHistory(
            Authentication authentication,
            @RequestParam(defaultValue = "10") @Min(1) @Max(100) int limit,
            @RequestParam(defaultValue = "0") @Min(0) int offset
    ) {
        String userEmail = authentication != null ? authentication.getName() : "anonymous";
        return ResponseEntity.ok(processingHistoryService.getHistory(userEmail, limit, offset));
    }
}
