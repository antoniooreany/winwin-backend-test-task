package com.winwintravel.authapi.process;

import org.springframework.stereotype.Service;

@Service
public class ProcessService {

    private final DataApiClient dataApiClient;
    private final ProcessingLogRepository processingLogRepository;

    public ProcessService(
            DataApiClient dataApiClient,
            ProcessingLogRepository processingLogRepository
    ) {
        this.dataApiClient = dataApiClient;
        this.processingLogRepository = processingLogRepository;
    }

    public ProcessResponse processText(ProcessRequest request) {
        return processText(request, "anonymous");
    }

    public ProcessResponse processText(ProcessRequest request, String userEmail) {
        String input = request != null && request.text() != null ? request.text() : "";
        String output = dataApiClient.transform(input);

        ProcessingLog log = new ProcessingLog();
        log.setUserEmail(userEmail);
        log.setInputText(input);
        log.setOutputText(output);
        processingLogRepository.save(log);

        return new ProcessResponse(output);
    }
}
