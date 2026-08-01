package com.winwintravel.authapi.process;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProcessingHistoryService {

    private final ProcessingLogRepository processingLogRepository;

    public ProcessingHistoryService(ProcessingLogRepository processingLogRepository) {
        this.processingLogRepository = processingLogRepository;
    }

    public List<ProcessingHistoryItemResponse> getHistory(String userEmail, int limit, int offset) {
        int safeLimit = Math.min(Math.max(limit, 1), 50);
        int safeOffset = Math.max(offset, 0);
        int page = safeOffset / safeLimit;

        Pageable pageable = PageRequest.of(
                page,
                safeLimit,
                Sort.by(Sort.Direction.DESC, "createdAt")
        );

        return processingLogRepository
                .findByUserEmailOrderByCreatedAtDesc(userEmail, pageable)
                .getContent()
                .stream()
                .map(item -> new ProcessingHistoryItemResponse(
                        item.getId(),
                        item.getInputText(),
                        item.getOutputText(),
                        item.getCreatedAt()
                ))
                .toList();
    }
}
