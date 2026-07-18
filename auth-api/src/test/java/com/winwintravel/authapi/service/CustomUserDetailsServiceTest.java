package com.winwintravel.authapi.service;

import com.winwintravel.authapi.repository.UserRepository;
import com.winwintravel.authapi.user.User;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CustomUserDetailsServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void loadUserByUsernameShouldReturnUserDetails() {
        User user = new User();
        user.setEmail("a@a.com");
        user.setPassword("encoded-pass");

        when(userRepository.findByEmail("a@a.com")).thenReturn(Optional.of(user));

        var userDetails = customUserDetailsService.loadUserByUsername("a@a.com");

        assertEquals("a@a.com", userDetails.getUsername());
        assertEquals("encoded-pass", userDetails.getPassword());
        assertFalse(userDetails.getAuthorities().isEmpty());
    }

    @Test
    void loadUserByUsernameShouldThrowWhenUserNotFound() {
        when(userRepository.findByEmail("missing@a.com")).thenReturn(Optional.empty());

        assertThrows(UsernameNotFoundException.class,
                () -> customUserDetailsService.loadUserByUsername("missing@a.com"));
    }
}
