package com.winwintravel.authapi.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import static org.mockito.ArgumentMatchers.any;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.winwintravel.authapi.audit.AuthAuditLogService;
import com.winwintravel.authapi.auth.JwtService;
import com.winwintravel.authapi.auth.dto.AuthResponse;
import com.winwintravel.authapi.auth.dto.LoginRequest;
import com.winwintravel.authapi.auth.dto.RegisterRequest;
import com.winwintravel.authapi.exception.UserAlreadyExistsException;
import com.winwintravel.authapi.repository.UserRepository;
import com.winwintravel.authapi.user.User;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    private static final String VALID_EMAIL = "example@email.com";

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @Mock
    private AuthenticationManager authenticationManager;

    @Mock
    private AuthAuditLogService authAuditLogService;

    @InjectMocks
    private AuthService authService;

    @Test
    void registerShouldSaveNewUserWithEncodedPassword() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail(VALID_EMAIL);
        request.setPassword("pass");

        when(userRepository.existsByEmail(VALID_EMAIL)).thenReturn(false);
        when(passwordEncoder.encode("pass")).thenReturn("encoded-pass");

        authService.register(request);

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        verify(passwordEncoder).encode("pass");

        User savedUser = userCaptor.getValue();
        assertEquals(VALID_EMAIL, savedUser.getEmail());
        assertEquals("encoded-pass", savedUser.getPassword());
    }

    @Test
    void registerShouldThrowWhenUserAlreadyExists() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail(VALID_EMAIL);
        request.setPassword("pass");

        when(userRepository.existsByEmail(VALID_EMAIL)).thenReturn(true);

        UserAlreadyExistsException ex = assertThrows(UserAlreadyExistsException.class,
                () -> authService.register(request));

        assertEquals("User already exists", ex.getMessage());
        verify(userRepository, never()).save(any());
        verify(passwordEncoder, never()).encode(any());
    }

    @Test
    void loginShouldAuthenticateAndReturnToken() {
        LoginRequest request = new LoginRequest();
        request.setEmail(VALID_EMAIL);
        request.setPassword("pass");

        when(jwtService.generateToken(VALID_EMAIL)).thenReturn("jwt-token");

        AuthResponse response = authService.login(request);

        verify(authenticationManager).authenticate(
                any(UsernamePasswordAuthenticationToken.class)
        );
        verify(authAuditLogService).logLoginAttempt(VALID_EMAIL, true);
        verify(jwtService).generateToken(VALID_EMAIL);
        assertNotNull(response);
        assertEquals("jwt-token", response.getToken());
    }
}
