package com.rihla.assistantservice.controller;

import com.rihla.assistantservice.dto.ChatRequest;
import com.rihla.assistantservice.dto.ChatResponse;
import com.rihla.assistantservice.service.AssistantService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/assistant")
@RequiredArgsConstructor
public class AssistantController {

    private final AssistantService service;

    @PostMapping("/chat")
    public ResponseEntity<ChatResponse> chat(@RequestBody ChatRequest request) {
        return ResponseEntity.ok(service.chat(request));
    }
}
