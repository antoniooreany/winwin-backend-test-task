package com.winwintravel.authapi.process;

import com.winwintravel.authapi.repository.UserRepository;
import com.winwintravel.authapi.user.User;
import org.springframework.stereotype.Service;
import java.time.Instant;

@Service
public class ProcessService {

    private final DataApiClient dataApiClient;
    private final ProcessingLogRepository processingLogRepository;
    private final UserRepository userRepository;

    public ProcessService(
            DataApiClient dataApiClient,
            ProcessingLogRepository processingLogRepository,
            UserRepository userRepository
    ) {
        this.dataApiClient = dataApiClient;
        this.processingLogRepository = processingLogRepository;
        this.userRepository = userRepository;
    }

    public ProcessResponse processText(ProcessRequest request) {
        return processText(request, "anonymous");
    }

    public ProcessResponse processText(ProcessRequest request, String userEmail) {
        String input = request != null && request.text() != null ? request.text() : "";
        String output = dataApiClient.transform(input);

        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalStateException("User not found: " + userEmail));

        ProcessingLog log = new ProcessingLog();
        log.setUser(user);
        log.setUserEmail(userEmail);
        log.setInputText(input);
        log.setOutputText(output);
        log.setCreatedAt(Instant.now());

        processingLogRepository.save(log);

        return new ProcessResponse(output);
    }
}

