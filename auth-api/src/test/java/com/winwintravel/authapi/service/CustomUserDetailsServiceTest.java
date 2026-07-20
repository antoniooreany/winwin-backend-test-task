package com.winwintravel.authapi.service;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import static org.mockito.Mockito.when;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import com.winwintravel.authapi.repository.UserRepository;
import com.winwintravel.authapi.user.User;

@ExtendWith(MockitoExtension.class)
class CustomUserDetailsServiceTest {

    private static final String VALID_EMAIL = "example@email.com";

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void loadUserByUsernameShouldReturnUserDetails() {
        User user = new User();
        user.setEmail(VALID_EMAIL);
        user.setPassword("encoded-pass");

        when(userRepository.findByEmail(VALID_EMAIL)).thenReturn(Optional.of(user));

        var userDetails = customUserDetailsService.loadUserByUsername(VALID_EMAIL);

        assertEquals(VALID_EMAIL, userDetails.getUsername());
        assertEquals("encoded-pass", userDetails.getPassword());
        assertFalse(userDetails.getAuthorities().isEmpty());
    }

    @Test
    void loadUserByUsernameShouldThrowWhenUserNotFound() {
        when(userRepository.findByEmail(VALID_EMAIL)).thenReturn(Optional.empty());

        UsernameNotFoundException ex = assertThrows(UsernameNotFoundException.class,
                () -> customUserDetailsService.loadUserByUsername(VALID_EMAIL));

        assertEquals(String.format("User not found: %s", VALID_EMAIL), ex.getMessage());
    }
}
