package com.winwintravel.authapi.process;

import java.time.Instant;

public record ProcessingHistoryItemResponse(
        Long id,
        String inputText,
        String outputText,
        Instant createdAt
) {}
