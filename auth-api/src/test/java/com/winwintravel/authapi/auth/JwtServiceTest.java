package com.winwintravel.authapi.auth;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

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

    private static final String JWT_SECRET_RAW = "test-jwt-secret-key-1234567890123456";

    private static final String JWT_SECRET = Base64.getEncoder().encodeToString(
            JWT_SECRET_RAW.getBytes(StandardCharsets.UTF_8)
    );

    private static final String VALID_EMAIL = "example@email.com";
    private static final String OTHER_EMAIL = "other@email.com";

    private JwtService jwtService;

    @BeforeEach
    void setUp() {
        jwtService = new JwtService();
        ReflectionTestUtils.setField(jwtService, "secret", JWT_SECRET);
    }

    @Test
    void shouldGenerateToken() {
        String token = jwtService.generateToken(VALID_EMAIL);

        assertNotNull(token);
        assertFalse(token.isBlank());
    }

    @Test
    void shouldExtractUsernameImmediatelyAfterGeneration() {
        String token = jwtService.generateToken(VALID_EMAIL);

        String username = jwtService.extractUsername(token);

        assertEquals(VALID_EMAIL, username);
    }

    @Test
    void shouldValidateTokenForMatchingUsername() {
        String token = jwtService.generateToken(VALID_EMAIL);

        boolean valid = jwtService.isTokenValid(token, VALID_EMAIL);

        assertTrue(valid);
    }

    @Test
    void shouldInvalidateTokenForDifferentUsername() {
        String token = jwtService.generateToken(VALID_EMAIL);

        boolean valid = jwtService.isTokenValid(token, OTHER_EMAIL);

        assertFalse(valid);
    }

    @Test
    void shouldThrowForMalformedToken() {
        JwtException ex = assertThrows(
                JwtException.class,
                () -> jwtService.extractUsername("not-a-jwt-token")
        );

        assertNotNull(ex.getMessage());
    }
}
