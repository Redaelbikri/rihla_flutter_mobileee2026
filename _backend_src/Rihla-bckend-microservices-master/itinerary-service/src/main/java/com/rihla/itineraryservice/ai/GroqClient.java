package com.rihla.itineraryservice.ai;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.List;

@Component
public class GroqClient {

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${ai.api.url}")
    private String apiUrl;

    @Value("${ai.api.key}")
    private String apiKey;

    @Value("${ai.model}")
    private String model;

    public String chat(String systemPrompt, String userPrompt) {
        GroqChatRequest req = new GroqChatRequest(
                model,
                List.of(
                        new GroqChatRequest.Message("system", systemPrompt),
                        new GroqChatRequest.Message("user", userPrompt)
                ),
                0.7
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Authorization", "Bearer " + apiKey);

        HttpEntity<GroqChatRequest> entity = new HttpEntity<>(req, headers);

        ResponseEntity<GroqChatResponse> resp =
                restTemplate.exchange(apiUrl, HttpMethod.POST, entity, GroqChatResponse.class);

        GroqChatResponse body = resp.getBody();
        if (body == null || body.choices() == null || body.choices().isEmpty()) return "";

        var msg = body.choices().get(0).message();
        return msg == null || msg.content() == null ? "" : msg.content();
    }
}
