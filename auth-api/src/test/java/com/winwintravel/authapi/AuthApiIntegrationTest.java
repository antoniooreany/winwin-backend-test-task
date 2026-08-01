package com.winwintravel.authapi;

import com.winwintravel.authapi.process.DataApiClient;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentMatchers;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

import static org.mockito.Mockito.when;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
class AuthApiIntegrationTest {

    static final PostgreSQLContainer<?> postgres =
            new PostgreSQLContainer<>("postgres:16-alpine")
                    .withDatabaseName("appdb")
                    .withUsername("appuser")
                    .withPassword("apppass");

    private static final HttpClient httpClient = HttpClient.newHttpClient();

    @MockitoBean
    private DataApiClient dataApiClient;

    @LocalServerPort
    private int port;

    @BeforeAll
    static void beforeAll() {
        postgres.start();
    }

    @AfterAll
    static void afterAll() {
        postgres.stop();
    }

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "validate");
        registry.add("spring.flyway.enabled", () -> "true");

        registry.add("jwt.secret", () -> "verysecretkeyverysecretkeyverysecretkey123456");
        registry.add("jwt.expiration", () -> "3600000");
        registry.add("data-api.base-url", () -> "http://localhost:9999");
        registry.add("data-api.internal-token", () -> "test-internal-token");
    }

    @Test
    void endToEnd_register_login_and_process() throws IOException, InterruptedException {
        when(dataApiClient.transform(ArgumentMatchers.eq("hello")))
                .thenReturn("olleh");

        HttpResponse<String> registerResponse = postJson(
                "/api/auth/register",
                """
                {
                  "email": "testcontainers@example.com",
                  "password": "secret123"
                }
                """,
                null
        );
        Assertions.assertEquals(HttpStatus.CREATED.value(), registerResponse.statusCode());

        HttpResponse<String> loginResponse = postJson(
                "/api/auth/login",
                """
                {
                  "email": "testcontainers@example.com",
                  "password": "secret123"
                }
                """,
                null
        );
        Assertions.assertEquals(HttpStatus.OK.value(), loginResponse.statusCode());

        String token = extractJsonValue(loginResponse.body(), "token");
        Assertions.assertNotNull(token);
        Assertions.assertFalse(token.isBlank());

        HttpResponse<String> processResponse = postJson(
                "/api/process",
                """
                {
                  "text": "hello"
                }
                """,
                token
        );
        Assertions.assertEquals(HttpStatus.OK.value(), processResponse.statusCode());
        Assertions.assertTrue(processResponse.body().contains("\"result\":\"olleh\""));
    }

    private HttpResponse<String> postJson(String path, String jsonBody, String bearerToken)
            throws IOException, InterruptedException {

        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:" + port + path))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(jsonBody));

        if (bearerToken != null && !bearerToken.isBlank()) {
            builder.header("Authorization", "Bearer " + bearerToken);
        }

        return httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString());
    }

    private String extractJsonValue(String json, String fieldName) {
        String pattern = "\"" + fieldName + "\":\"";
        int start = json.indexOf(pattern);
        if (start < 0) {
            return null;
        }

        int valueStart = start + pattern.length();
        int valueEnd = json.indexOf("\"", valueStart);
        if (valueEnd < 0) {
            return null;
        }

        return json.substring(valueStart, valueEnd);
    }
}