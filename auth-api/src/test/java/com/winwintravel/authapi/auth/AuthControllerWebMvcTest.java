package com.winwintravel.authapi.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.winwintravel.authapi.auth.dto.AuthResponse;
import com.winwintravel.authapi.auth.dto.LoginRequest;
import com.winwintravel.authapi.auth.dto.RegisterRequest;
import com.winwintravel.authapi.security.JwtAuthenticationFilter;
import com.winwintravel.authapi.service.AuthService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
@Import({com.winwintravel.authapi.security.SecurityConfig.class, AuthControllerWebMvcTest.TestConfig.class})
class AuthControllerWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AuthService authService;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @MockBean
    private UserDetailsService userDetailsService;

    @MockBean
    private AuthenticationConfiguration authenticationConfiguration;

    @MockBean
    private AuthenticationManager authenticationManager;

    @TestConfiguration
    static class TestConfig {
        @Bean
        PasswordEncoder passwordEncoder() {
            return new BCryptPasswordEncoder();
        }
    }

    @Test
    void registerShouldReturnCreated() throws Exception {
        RegisterRequest request = new RegisterRequest();
        request.setEmail("a@a.com");
        request.setPassword("pass");

        doNothing().when(authService).register(any(RegisterRequest.class));

        mockMvc.perform(post("/api/auth/register")
                .contentType("application/json")
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated());
    }

    @Test
    void loginShouldReturnToken() throws Exception {
        LoginRequest request = new LoginRequest();
        request.setEmail("a@a.com");
        request.setPassword("pass");

        when(authService.login(any(LoginRequest.class)))
                .thenReturn(new AuthResponse("jwt-token"));

        mockMvc.perform(post("/api/auth/login")
                .contentType("application/json")
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("jwt-token"));
    }
}
