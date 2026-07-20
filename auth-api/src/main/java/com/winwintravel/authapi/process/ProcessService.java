package com.winwintravel.authapi.process;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
public class ProcessService {

    private final DataApiClient dataApiClient;
    private final ProcessingLogRepository processingLogRepository;

    public ProcessService(DataApiClient dataApiClient, ProcessingLogRepository processingLogRepository) {
        this.dataApiClient = dataApiClient;
        this.processingLogRepository = processingLogRepository;
    }

    public ProcessResponse processText(ProcessRequest request) {
        String input = request.text();
        String output = dataApiClient.transform(input);

        String userEmail = resolveCurrentUserEmail();

        ProcessingLog log = new ProcessingLog();
        log.setUserEmail(userEmail);
        log.setInputText(input);
        log.setOutputText(output);
        processingLogRepository.save(log);

        return new ProcessResponse(output);
    }

    private String resolveCurrentUserEmail() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || authentication.getName() == null) {
            return "unknown";
        }
        return authentication.getName();
    }
}
