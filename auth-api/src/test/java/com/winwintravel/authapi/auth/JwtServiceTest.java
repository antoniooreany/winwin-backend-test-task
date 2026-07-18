package com.winwintravel.authapi.auth;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class JwtServiceTest {

    private JwtService jwtService;

    @BeforeEach
    void setUp() {
        jwtService = new JwtService();
        ReflectionTestUtils.setField(
                jwtService,
                "secret",
                "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY="
        );
    }

    @Test
    void shouldGenerateToken() {
        String token = jwtService.generateToken("a@a.com");

        assertNotNull(token);
        assertFalse(token.isBlank());
    }

    @Test
    void shouldExtractUsernameImmediatelyAfterGeneration() {
        String token = jwtService.generateToken("a@a.com");

        String username = jwtService.extractUsername(token);

        assertEquals("a@a.com", username);
    }

    @Test
    void shouldValidateTokenForMatchingUsername() {
        String token = jwtService.generateToken("a@a.com");

        boolean valid = jwtService.isTokenValid(token, "a@a.com");

        assertTrue(valid);
    }

    @Test
    void shouldInvalidateTokenForDifferentUsername() {
        String token = jwtService.generateToken("a@a.com");

        boolean valid = jwtService.isTokenValid(token, "b@b.com");

        assertFalse(valid);
    }
}
