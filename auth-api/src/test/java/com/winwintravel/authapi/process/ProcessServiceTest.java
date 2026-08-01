package com.winwintravel.authapi.process;

import com.winwintravel.authapi.repository.UserRepository;
import com.winwintravel.authapi.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ProcessServiceTest {

    @Mock
    private DataApiClient dataApiClient;

    @Mock
    private ProcessingLogRepository processingLogRepository;

    @Mock
    private UserRepository userRepository;

    private ProcessService processService;

    @BeforeEach
    void setUp() {
        processService = new ProcessService(dataApiClient, processingLogRepository, userRepository);
    }

    @Test
    void processText_shouldPersistAnonymousUser_andUseDataApiResult() {
        User user = new User();
        user.setEmail("anonymous");

        when(dataApiClient.transform("hello")).thenReturn("olleh");
        when(userRepository.findByEmail("anonymous")).thenReturn(Optional.of(user));

        ProcessResponse response = processService.processText(new ProcessRequest("hello"));

        assertEquals("olleh", response.result());

        ArgumentCaptor<ProcessingLog> captor = ArgumentCaptor.forClass(ProcessingLog.class);
        verify(processingLogRepository).save(captor.capture());

        ProcessingLog savedLog = captor.getValue();
        assertEquals(user, savedLog.getUser());
        assertEquals("anonymous", savedLog.getUserEmail());
        assertEquals("hello", savedLog.getInputText());
        assertEquals("olleh", savedLog.getOutputText());
    }

    @Test
    void processText_shouldPersistProvidedUserEmail_andUseDataApiResult() {
        User user = new User();
        user.setEmail("user@test.com");

        when(dataApiClient.transform("hello")).thenReturn("olleh");
        when(userRepository.findByEmail("user@test.com")).thenReturn(Optional.of(user));

        ProcessResponse response =
                processService.processText(new ProcessRequest("hello"), "user@test.com");

        assertEquals("olleh", response.result());

        ArgumentCaptor<ProcessingLog> captor = ArgumentCaptor.forClass(ProcessingLog.class);
        verify(processingLogRepository).save(captor.capture());

        ProcessingLog savedLog = captor.getValue();
        assertEquals(user, savedLog.getUser());
        assertEquals("user@test.com", savedLog.getUserEmail());
        assertEquals("hello", savedLog.getInputText());
        assertEquals("olleh", savedLog.getOutputText());
    }

    @Test
    void processText_shouldHandleNullRequest() {
        User user = new User();
        user.setEmail("anonymous");

        when(dataApiClient.transform("")).thenReturn("");
        when(userRepository.findByEmail("anonymous")).thenReturn(Optional.of(user));

        ProcessResponse response = processService.processText(null);

        assertNotNull(response);
        assertEquals("", response.result());

        ArgumentCaptor<ProcessingLog> captor = ArgumentCaptor.forClass(ProcessingLog.class);
        verify(processingLogRepository).save(captor.capture());

        ProcessingLog savedLog = captor.getValue();
        assertEquals(user, savedLog.getUser());
        assertEquals("anonymous", savedLog.getUserEmail());
        assertEquals("", savedLog.getInputText());
        assertEquals("", savedLog.getOutputText());
    }
}
