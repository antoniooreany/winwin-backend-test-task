package com.winwintravel.authapi.process;

import org.springframework.data.domain.Sort;
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

        var pageable = new OffsetBasedPageRequest(
                safeOffset,
                safeLimit + 1,
                Sort.by(Sort.Direction.DESC, "createdAt")
        );

        var content = processingLogRepository
                .findByUserEmailOrderByCreatedAtDesc(userEmail, pageable)
                .getContent();

        boolean hasMore = content.size() > safeLimit;

        List<ProcessingHistoryItemResponse> items = content.stream()
                .limit(safeLimit)
                .map(item -> new ProcessingHistoryItemResponse(
                        item.getId(),
                        item.getInputText(),
                        item.getOutputText(),
                        item.getCreatedAt()
                ))
                .toList();

        return new ProcessingHistoryResponse(items, safeLimit, safeOffset, hasMore);
    }
}
