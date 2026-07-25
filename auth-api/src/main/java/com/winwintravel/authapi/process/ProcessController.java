package com.winwintravel.authapi.process;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/process")
public class ProcessController {

    private final ProcessService processService;

    public ProcessController(ProcessService processService) {
        this.processService = processService;
    }

    @PostMapping
    public ResponseEntity<ProcessResponse> process(@RequestBody ProcessRequest request, Authentication authentication) {
        String userEmail = authentication != null ? authentication.getName() : "anonymous";
        return ResponseEntity.ok(processService.processText(request, userEmail));
    }
}
