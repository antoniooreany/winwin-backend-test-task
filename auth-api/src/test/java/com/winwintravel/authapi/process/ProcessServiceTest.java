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
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

@ExtendWith(MockitoExtension.class)
class ProcessServiceTest {

    private static final String VALID_EMAIL = "example@email.com";

    private static final String VALID_TEXT = "hello";

    @Mock
    private DataApiClient dataApiClient;

    @Mock
    private ProcessingLogRepository processingLogRepository;

    @Mock
    private SecurityContext securityContext;

    @Mock
    private Authentication authentication;

    @InjectMocks
    private ProcessService processService;

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void processText_shouldCallDataApi_andPersistProcessingLog_withAuthenticatedUser() {
        ProcessRequest request = new ProcessRequest(VALID_TEXT);

        when(dataApiClient.transform(VALID_TEXT)).thenReturn(VALID_TEXT);
        when(securityContext.getAuthentication()).thenReturn(authentication);
        when(authentication.getName()).thenReturn(VALID_EMAIL);

        SecurityContextHolder.setContext(securityContext);

        ProcessResponse response = processService.processText(request);

        assertNotNull(response);
        assertEquals(VALID_TEXT, response.result());

        verify(dataApiClient).transform(VALID_TEXT);

        ArgumentCaptor<ProcessingLog> logCaptor = ArgumentCaptor.forClass(ProcessingLog.class);
        verify(processingLogRepository).save(logCaptor.capture());

        ProcessingLog savedLog = logCaptor.getValue();
        assertEquals(VALID_EMAIL, savedLog.getUserEmail());
        assertEquals(VALID_TEXT, savedLog.getInputText());
        assertEquals(VALID_TEXT, savedLog.getOutputText());
        assertNotNull(savedLog.getCreatedAt());
    }

    @Test
    void processText_shouldPersistUnknownUser_whenAuthenticationIsMissing() {
        ProcessRequest request = new ProcessRequest(VALID_TEXT);

        when(dataApiClient.transform(VALID_TEXT)).thenReturn(VALID_TEXT);

        SecurityContextHolder.clearContext();

        ProcessResponse response = processService.processText(request);

        assertNotNull(response);
        assertEquals(VALID_TEXT, response.result());

        ArgumentCaptor<ProcessingLog> logCaptor = ArgumentCaptor.forClass(ProcessingLog.class);
        verify(processingLogRepository).save(logCaptor.capture());

        ProcessingLog savedLog = logCaptor.getValue();
        assertEquals("unknown", savedLog.getUserEmail());
        assertEquals(VALID_TEXT, savedLog.getInputText());
        assertEquals(VALID_TEXT, savedLog.getOutputText());
    }
}
