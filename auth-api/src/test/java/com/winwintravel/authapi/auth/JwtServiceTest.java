package com.winwintravel.authapi.auth;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;

class JwtServiceTest {

    private JwtService jwtService;

    @BeforeEach
    void setUp() {
        jwtService = new JwtService();
        ReflectionTestUtils.setField(jwtService, "secret", "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=");
    }

    @Test
    void shouldGenerateAndExtractUsername() {
        String token = jwtService.generateToken("a@a.com");

        assertNotNull(token);
        assertEquals("a@a.com", jwtService.extractUsername(token));
    }

    @Test
    void shouldValidateTokenForSameUsername() {
        String token = jwtService.generateToken("a@a.com");

        assertTrue(jwtService.isTokenValid(token, "a@a.com"));
        assertFalse(jwtService.isTokenValid(token, "b@b.com"));
    }
}
