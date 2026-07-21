package com.winwintravel.authapi.process;

import org.junit.jupiter.api.AfterEach;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

@ExtendWith(MockitoExtension.class)
class ProcessServiceTest {

    @Mock
    private DataApiClient dataApiClient;

    @Mock
    private ProcessingLogRepository processingLogRepository;

    @InjectMocks
    private ProcessService processService;

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void shouldCallDataApiAndPersistLogForAuthenticatedUser() {
        // given
        var authentication = new UsernamePasswordAuthenticationToken("user@example.com", "ignored");
        SecurityContextHolder.getContext().setAuthentication(authentication);

        when(dataApiClient.transform("hello")).thenReturn("HELLO");

        ProcessRequest request = new ProcessRequest("hello");

        // when
        ProcessResponse response = processService.processText(request);

        // then
        assertNotNull(response);
        assertEquals("HELLO", response.result());

        verify(dataApiClient).transform("hello");

        ArgumentCaptor<ProcessingLog> logCaptor = ArgumentCaptor.forClass(ProcessingLog.class);
        verify(processingLogRepository).save(logCaptor.capture());

        ProcessingLog savedLog = logCaptor.getValue();
        assertEquals("user@example.com", savedLog.getUserEmail());
        assertEquals("hello", savedLog.getInputText());
        assertEquals("HELLO", savedLog.getOutputText());
        assertNotNull(savedLog.getCreatedAt());
    }
}
