package com.winwintravel.authapi.process;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/process")
public class ProcessHistoryController {

    private final ProcessingHistoryService processingHistoryService;

    public ProcessHistoryController(ProcessingHistoryService processingHistoryService) {
        this.processingHistoryService = processingHistoryService;
    }

    @GetMapping("/history")
    public ResponseEntity<List<ProcessingHistoryItemResponse>> getHistory(
            Authentication authentication,
            @RequestParam(defaultValue = "10") int limit,
            @RequestParam(defaultValue = "0") int offset
    ) {
        String userEmail = authentication != null ? authentication.getName() : "anonymous";
        return ResponseEntity.ok(processingHistoryService.getHistory(userEmail, limit, offset));
    }
}
