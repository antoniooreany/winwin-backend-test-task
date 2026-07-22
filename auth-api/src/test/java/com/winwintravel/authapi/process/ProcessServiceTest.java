package com.winwintravel.authapi.process;

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

@ExtendWith(MockitoExtension.class)
class ProcessServiceTest {

    @Mock
    private DataApiClient dataApiClient;

    @Mock
    private ProcessingLogRepository processingLogRepository;

    @InjectMocks
    private ProcessService processService;

    @Test
    void processText_shouldPersistAnonymousUser_andUseDataApiResult() {
        ProcessRequest request = new ProcessRequest("hello world");

        when(dataApiClient.transform("hello world")).thenReturn("dlrow olleh");

        ProcessResponse response = processService.processText(request);

        assertNotNull(response);
        assertEquals("dlrow olleh", response.result());

        verify(dataApiClient).transform("hello world");

        ArgumentCaptor<ProcessingLog> logCaptor = ArgumentCaptor.forClass(ProcessingLog.class);
        verify(processingLogRepository).save(logCaptor.capture());

        ProcessingLog savedLog = logCaptor.getValue();
        assertEquals("anonymous", savedLog.getUserEmail());
        assertEquals("hello world", savedLog.getInputText());
        assertEquals("dlrow olleh", savedLog.getOutputText());
        assertNotNull(savedLog.getCreatedAt());
    }

    @Test
    void processText_shouldPersistProvidedUserEmail_andUseDataApiResult() {
        ProcessRequest request = new ProcessRequest("hello");
        String userEmail = "example@email.com";

        when(dataApiClient.transform("hello")).thenReturn("olleh");

        ProcessResponse response = processService.processText(request, userEmail);

        assertNotNull(response);
        assertEquals("olleh", response.result());

        verify(dataApiClient).transform("hello");

        ArgumentCaptor<ProcessingLog> logCaptor = ArgumentCaptor.forClass(ProcessingLog.class);
        verify(processingLogRepository).save(logCaptor.capture());

        ProcessingLog savedLog = logCaptor.getValue();
        assertEquals("example@email.com", savedLog.getUserEmail());
        assertEquals("hello", savedLog.getInputText());
        assertEquals("olleh", savedLog.getOutputText());
        assertNotNull(savedLog.getCreatedAt());
    }

    @Test
    void processText_shouldHandleNullRequest() {
        when(dataApiClient.transform("")).thenReturn("");

        ProcessResponse response = processService.processText(null, "example@email.com");

        assertNotNull(response);
        assertEquals("", response.result());

        verify(dataApiClient).transform("");

        ArgumentCaptor<ProcessingLog> logCaptor = ArgumentCaptor.forClass(ProcessingLog.class);
        verify(processingLogRepository).save(logCaptor.capture());

        ProcessingLog savedLog = logCaptor.getValue();
        assertEquals("example@email.com", savedLog.getUserEmail());
        assertEquals("", savedLog.getInputText());
        assertEquals("", savedLog.getOutputText());
        assertNotNull(savedLog.getCreatedAt());
    }
}
