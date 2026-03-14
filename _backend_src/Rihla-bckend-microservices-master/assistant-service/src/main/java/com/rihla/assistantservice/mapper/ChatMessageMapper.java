package com.rihla.assistantservice.mapper;

import com.rihla.assistantservice.entity.ChatMessage;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class ChatMessageMapper {

    public ChatMessage toEntity(String userId, String role, String content) {
        return ChatMessage.builder()
                .userId(userId)
                .role(role)
                .content(content)
                .timestamp(LocalDateTime.now())
                .build();
    }
}
