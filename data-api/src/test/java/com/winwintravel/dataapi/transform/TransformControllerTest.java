package com.winwintravel.dataapi.transform;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;

import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = "internal.token=test-internal-token"
)
class TransformControllerTest {

    @LocalServerPort
    private int port;

    @Test
    void shouldReturnTransformedTextForValidInternalToken() throws Exception {
        HttpURLConnection connection = openConnection("{\"text\":\"hello\"}", "test-internal-token");

        int status = connection.getResponseCode();
        String body = readBody(connection);

        assertEquals(200, status);
        assertTrue(body.contains("\"result\":\"HELLO\""));
    }

    @Test
    void shouldReturnForbiddenWhenHeaderIsMissing() throws Exception {
        HttpURLConnection connection = openConnection("{\"text\":\"hello\"}", null);

        int status = connection.getResponseCode();

        assertEquals(403, status);
    }

    @Test
    void shouldReturnForbiddenWhenHeaderIsInvalid() throws Exception {
        HttpURLConnection connection = openConnection("{\"text\":\"hello\"}", "wrong-token");

        int status = connection.getResponseCode();

        assertEquals(403, status);
    }

    private HttpURLConnection openConnection(String jsonBody, String internalToken) throws Exception {
        URI uri = URI.create("http://localhost:" + port + "/api/transform");
        HttpURLConnection connection = (HttpURLConnection) uri.toURL().openConnection();
        connection.setRequestMethod("POST");
        connection.setRequestProperty("Content-Type", "application/json");
        connection.setRequestProperty("Accept", "application/json");
        if (internalToken != null) {
            connection.setRequestProperty("X-Internal-Token", internalToken);
        }
        connection.setDoOutput(true);

        try (OutputStream os = connection.getOutputStream()) {
            os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
        }

        return connection;
    }

    private String readBody(HttpURLConnection connection) throws Exception {
        InputStream stream = connection.getResponseCode() >= 400
                ? connection.getErrorStream()
                : connection.getInputStream();

        if (stream == null) {
            return "";
        }

        try (stream) {
            return new String(stream.readAllBytes(), StandardCharsets.UTF_8);
        }
    }
}
