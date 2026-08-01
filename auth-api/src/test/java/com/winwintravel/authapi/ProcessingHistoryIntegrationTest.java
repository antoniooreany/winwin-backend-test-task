package com.winwintravel.authapi;

import org.junit.jupiter.api.Test;
import com.winwintravel.authapi.process.DataApiClient;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ProcessingHistoryIntegrationTest {

    @MockitoBean
    DataApiClient dataApiClient;

    @LocalServerPort
    int port;

    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Test
    void historyReturnsLatestUserEntries() throws Exception {
        org.mockito.Mockito.when(dataApiClient.transform("hello")).thenReturn("olleh");

        String email = "history-user+" + System.nanoTime() + "@example.com";
        String password = "password123";
        String baseUrl = "http://localhost:" + port;

        String registerJson = """
                {
                  "email": "%s",
                  "password": "%s"
                }
                """.formatted(email, password);

        HttpRequest registerRequest = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/auth/register"))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(registerJson))
                .build();

        HttpResponse<String> registerResponse = httpClient.send(registerRequest, HttpResponse.BodyHandlers.ofString());
        assertThat(registerResponse.statusCode()).isIn(200, 201);

        String loginJson = """
                {
                  "email": "%s",
                  "password": "%s"
                }
                """.formatted(email, password);

        HttpRequest loginRequest = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/auth/login"))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(loginJson))
                .build();

        HttpResponse<String> loginResponse = httpClient.send(loginRequest, HttpResponse.BodyHandlers.ofString());
        assertThat(loginResponse.statusCode()).isEqualTo(200);
        assertThat(loginResponse.body()).isNotBlank();

        String jwt = extractToken(loginResponse.body());
        assertThat(jwt).isNotBlank();

        String processJson = """
                {
                  "text": "hello"
                }
                """;

        HttpRequest processRequest = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/process"))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + jwt)
                .POST(HttpRequest.BodyPublishers.ofString(processJson))
                .build();

        HttpResponse<String> processResponse = httpClient.send(processRequest, HttpResponse.BodyHandlers.ofString());
        assertThat(processResponse.statusCode()).isEqualTo(200);

        HttpRequest historyRequest = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/process/history?limit=10&offset=0"))
                .header("Authorization", "Bearer " + jwt)
                .GET()
                .build();

        HttpResponse<String> historyResponse = httpClient.send(historyRequest, HttpResponse.BodyHandlers.ofString());
        assertThat(historyResponse.statusCode()).isEqualTo(200);
        assertThat(historyResponse.body()).contains("hello");
        assertThat(historyResponse.body()).contains("olleh");
    }

    private String extractToken(String json) {
        String marker = "\"token\":\"";
        int start = json.indexOf(marker);
        if (start >= 0) {
            int valueStart = start + marker.length();
            int valueEnd = json.indexOf('"', valueStart);
            if (valueEnd > valueStart) {
                return json.substring(valueStart, valueEnd);
            }
        }

        String altMarker = "\"jwt\":\"";
        start = json.indexOf(altMarker);
        if (start >= 0) {
            int valueStart = start + altMarker.length();
            int valueEnd = json.indexOf('"', valueStart);
            if (valueEnd > valueStart) {
                return json.substring(valueStart, valueEnd);
            }
        }

        throw new IllegalStateException("JWT token not found in login response: " + json);
    }
}




