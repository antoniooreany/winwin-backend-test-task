package com.winwintravel.authapi.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import io.jsonwebtoken.JwtException;

class JwtServiceTest {

    private JwtService jwtService;

    @BeforeEach
    void setUp() {
        jwtService = new JwtService();
        ReflectionTestUtils.setField(jwtService, "secret", "ZmFrZS1iYXNlNjQtc2VjcmV0LWtleS0xMjM0NTY3ODkwMTIzNDU2Nzg5MDEyMzQ1Njc4OTA=");
    }

    @Test
    void shouldGenerateToken() {
        String token = jwtService.generateToken("user@example.com");

        assertNotNull(token);
        assertFalse(token.isBlank());
    }

    @Test
    void shouldExtractUsernameImmediatelyAfterGeneration() {
        String token = jwtService.generateToken("user@example.com");

        String username = jwtService.extractUsername(token);

        assertEquals("user@example.com", username);
    }

    @Test
    void shouldValidateTokenForMatchingUsername() {
        String token = jwtService.generateToken("user@example.com");

        boolean valid = jwtService.isTokenValid(token, "user@example.com");

        assertTrue(valid);
    }

    @Test
    void shouldInvalidateTokenForDifferentUsername() {
        String token = jwtService.generateToken("user@example.com");

        boolean valid = jwtService.isTokenValid(token, "other@example.com");

        assertFalse(valid);
    }

    @Test
    void shouldThrowForMalformedToken() {
        assertThrows(JwtException.class, () -> jwtService.extractUsername("not-a-jwt-token"));
    }
}
