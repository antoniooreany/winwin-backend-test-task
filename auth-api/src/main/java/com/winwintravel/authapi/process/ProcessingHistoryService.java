package com.winwintravel.authapi.process;

import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProcessingHistoryService {

    private final ProcessingLogRepository processingLogRepository;

    public ProcessingHistoryService(ProcessingLogRepository processingLogRepository) {
        this.processingLogRepository = processingLogRepository;
    }

    public ProcessingHistoryResponse getHistory(String userEmail, int limit, int offset) {
        int safeLimit = Math.max(1, Math.min(limit, 100));
        int safeOffset = Math.max(0, offset);

        var pageRequest = PageRequest.of(safeOffset / safeLimit, safeLimit + 1);
        var page = processingLogRepository.findByUserEmailOrderByCreatedAtDesc(userEmail, pageRequest);

        List<ProcessingHistoryItemResponse> items = page.getContent().stream()
                .skip(safeOffset % safeLimit)
                .limit(safeLimit)
                .map(item -> new ProcessingHistoryItemResponse(
                        item.getId(),
                        item.getInputText(),
                        item.getOutputText(),
                        item.getCreatedAt()
                ))
                .toList();

        boolean hasMore = page.getContent().size() > (safeOffset % safeLimit) + safeLimit;

        return new ProcessingHistoryResponse(items, safeLimit, safeOffset, hasMore);
    }
}
