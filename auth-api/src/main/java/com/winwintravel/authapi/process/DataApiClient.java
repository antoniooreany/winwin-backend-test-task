package com.winwintravel.authapi.process;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class DataApiClient {

    private final RestClient restClient;
    private final String internalToken;

    public DataApiClient(
            @Value("${data-api.base-url}") String baseUrl,
            @Value("${data-api.internal-token}") String internalToken
    ) {
        this.internalToken = internalToken;
        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .build();
    }

    public String transform(String text) {
        ProcessRequest request = new ProcessRequest(text == null ? "" : text);

        try {
            ProcessResponse response = restClient.post()
                    .uri("/api/transform")
                    .header("X-Internal-Token", internalToken)
                    .contentType(MediaType.APPLICATION_JSON)
                    .accept(MediaType.APPLICATION_JSON)
                    .body(request)
                    .retrieve()
                    .body(ProcessResponse.class);

            if (response == null) {
                throw new IllegalStateException("Empty response from data-api");
            }

            return response.result();
        } catch (RestClientException e) {
            throw new IllegalStateException("Failed to call data-api", e);
        }
    }
}
