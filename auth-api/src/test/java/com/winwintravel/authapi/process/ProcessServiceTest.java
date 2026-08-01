package com.winwintravel.authapi.process;

import com.winwintravel.authapi.repository.UserRepository;
import com.winwintravel.authapi.user.User;
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

import java.util.Optional;

@ExtendWith(MockitoExtension.class)
class ProcessServiceTest {

    @Mock
    private DataApiClient dataApiClient;

    @Mock
    private ProcessingLogRepository processingLogRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private ProcessService processService;

    @Test
    void processText_shouldPersistAnonymousUser_andUseDataApiResult() {
        ProcessRequest request = new ProcessRequest("hello world");

        User user = new User();
        user.setId(1L);
        user.setEmail("anonymous");
        user.setPassword("secret");

        when(dataApiClient.transform("hello world")).thenReturn("dlrow olleh");
        when(userRepository.findByEmail("anonymous")).thenReturn(Optional.of(user));

        ProcessResponse response = processService.processText(request);

        assertNotNull(response);
        assertEquals("dlrow olleh", response.result());

        verify(dataApiClient).transform("hello world");
        verify(userRepository).findByEmail("anonymous");

        ArgumentCaptor<ProcessingLog> logCaptor = ArgumentCaptor.forClass(ProcessingLog.class);
        verify(processingLogRepository).save(logCaptor.capture());

        ProcessingLog savedLog = logCaptor.getValue();
        assertEquals("anonymous", savedLog.getUser().getEmail());
        assertEquals(1L, savedLog.getUser().getId());
        assertEquals("hello world", savedLog.getInputText());
        assertEquals("dlrow olleh", savedLog.getOutputText());
        assertNotNull(savedLog.getCreatedAt());
    }

    @Test
    void processText_shouldPersistProvidedUserEmail_andUseDataApiResult() {
        ProcessRequest request = new ProcessRequest("hello");
        String userEmail = "example@email.com";

        User user = new User();
        user.setId(2L);
        user.setEmail(userEmail);
        user.setPassword("secret");

        when(dataApiClient.transform("hello")).thenReturn("olleh");
        when(userRepository.findByEmail(userEmail)).thenReturn(Optional.of(user));

        ProcessResponse response = processService.processText(request, userEmail);

        assertNotNull(response);
        assertEquals("olleh", response.result());

        verify(dataApiClient).transform("hello");
        verify(userRepository).findByEmail(userEmail);

        ArgumentCaptor<ProcessingLog> logCaptor = ArgumentCaptor.forClass(ProcessingLog.class);
        verify(processingLogRepository).save(logCaptor.capture());

        ProcessingLog savedLog = logCaptor.getValue();
        assertEquals("example@email.com", savedLog.getUser().getEmail());
        assertEquals(2L, savedLog.getUser().getId());
        assertEquals("hello", savedLog.getInputText());
        assertEquals("olleh", savedLog.getOutputText());
        assertNotNull(savedLog.getCreatedAt());
    }

    @Test
    void processText_shouldHandleNullRequest() {
        String userEmail = "example@email.com";

        User user = new User();
        user.setId(3L);
        user.setEmail(userEmail);
        user.setPassword("secret");

        when(dataApiClient.transform("")).thenReturn("");
        when(userRepository.findByEmail(userEmail)).thenReturn(Optional.of(user));

        ProcessResponse response = processService.processText(null, userEmail);

        assertNotNull(response);
        assertEquals("", response.result());

        verify(dataApiClient).transform("");
        verify(userRepository).findByEmail(userEmail);

        ArgumentCaptor<ProcessingLog> logCaptor = ArgumentCaptor.forClass(ProcessingLog.class);
        verify(processingLogRepository).save(logCaptor.capture());

        ProcessingLog savedLog = logCaptor.getValue();
        assertEquals("example@email.com", savedLog.getUser().getEmail());
        assertEquals(3L, savedLog.getUser().getId());
        assertEquals("", savedLog.getInputText());
        assertEquals("", savedLog.getOutputText());
        assertNotNull(savedLog.getCreatedAt());
    }
}
