package com.winwintravel.authapi.process;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class ProcessController {

    private final ProcessService processService;

    public ProcessController(ProcessService processService) {
        this.processService = processService;
    }

    @PostMapping("/process")
    public ResponseEntity<ProcessResponse> process(@RequestBody ProcessRequest request) {
        ProcessResponse response = processService.processText(request);
        return ResponseEntity.status(HttpStatus.OK).body(response);
    }
}
