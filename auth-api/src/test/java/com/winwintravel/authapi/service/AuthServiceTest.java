package com.winwintravel.authapi.service;

import com.winwintravel.authapi.auth.JwtService;
import com.winwintravel.authapi.auth.dto.AuthResponse;
import com.winwintravel.authapi.auth.dto.LoginRequest;
import com.winwintravel.authapi.auth.dto.RegisterRequest;
import com.winwintravel.authapi.repository.UserRepository;
import com.winwintravel.authapi.user.User;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @Mock
    private AuthenticationManager authenticationManager;

    @InjectMocks
    private AuthService authService;

    @Test
    void registerShouldSaveNewUserWithEncodedPassword() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail("a@a.com");
        request.setPassword("pass");

        when(userRepository.existsByEmail("a@a.com")).thenReturn(false);
        when(passwordEncoder.encode("pass")).thenReturn("encoded-pass");

        authService.register(request);

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());

        User savedUser = userCaptor.getValue();
        assertEquals("a@a.com", savedUser.getEmail());
        assertEquals("encoded-pass", savedUser.getPassword());
    }

    @Test
    void registerShouldThrowWhenUserAlreadyExists() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail("a@a.com");
        request.setPassword("pass");

        when(userRepository.existsByEmail("a@a.com")).thenReturn(true);

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> authService.register(request));

        assertEquals("User already exists", ex.getMessage());
        verify(userRepository, never()).save(any());
    }

    @Test
    void loginShouldAuthenticateAndReturnToken() {
        LoginRequest request = new LoginRequest();
        request.setEmail("a@a.com");
        request.setPassword("pass");

        when(jwtService.generateToken("a@a.com")).thenReturn("jwt-token");

        AuthResponse response = authService.login(request);

        verify(authenticationManager).authenticate(
                any(UsernamePasswordAuthenticationToken.class)
        );
        assertNotNull(response);
        assertEquals("jwt-token", response.getToken());
    }
}
