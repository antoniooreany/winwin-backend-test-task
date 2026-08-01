package com.winwintravel.authapi.process;

import java.util.List;

public record ProcessingHistoryResponse(
        List<ProcessingHistoryItemResponse> items,
        int limit,
        int offset,
        boolean hasMore
) {
}
