package com.rihla.assistantservice.service;

import com.rihla.assistantservice.dto.ChatRequest;
import com.rihla.assistantservice.dto.ChatResponse;
import com.rihla.assistantservice.entity.ChatMessage;
import com.rihla.assistantservice.mapper.ChatMessageMapper;
import com.rihla.assistantservice.repository.ChatMessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;

@Service
@RequiredArgsConstructor
public class AssistantService {

    @Value("${ai.api.key}")
    private String apiKey;

    @Value("${ai.api.url}")
    private String apiUrl;

    private final RestTemplate restTemplate;
    private final ChatMessageRepository repository;
    private final ChatMessageMapper mapper;

    public ChatResponse chat(ChatRequest request) {
        try {
            // Save user message
            ChatMessage userMessage = mapper.toEntity(request.getUserId(), "user", request.getMessage());
            repository.save(userMessage);

            // Load conversation history
            List<ChatMessage> history = repository.findByUserIdOrderByTimestampAsc(request.getUserId());

            // Prepare AI messages
            List<Map<String, String>> messages = new ArrayList<>();
            messages.add(Map.of(
                    "role", "system",
                    "content", "You are Rihla AI, Moroccan travel expert. Be concise."
            ));
            for (ChatMessage msg : history) {
                messages.add(Map.of(
                        "role", msg.getRole(),
                        "content", msg.getContent()
                ));
            }

            // Build Groq request
            Map<String, Object> body = new HashMap<>();
            body.put("model", "llama-3.3-70b-versatile"); // ✅ match exactly what you see in Groq Playground
            body.put("messages", messages);
            body.put("temperature", 1);
            body.put("max_completion_tokens", 2000);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + apiKey); // Groq expects Bearer token

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

            ResponseEntity<Map> response = restTemplate.postForEntity(apiUrl, entity, Map.class);

            // Parse Groq response
            List choices = (List) response.getBody().get("choices");
            Map firstChoice = (Map) choices.get(0);
            Map message = (Map) firstChoice.get("message");
            String reply = (String) message.get("content");

            // Save assistant reply
            ChatMessage assistantMessage = mapper.toEntity(request.getUserId(), "assistant", reply);
            repository.save(assistantMessage);

            return new ChatResponse(reply);

        } catch (Exception e) {
            e.printStackTrace();
            return new ChatResponse("Assistant unavailable.");
        }
    }
}
