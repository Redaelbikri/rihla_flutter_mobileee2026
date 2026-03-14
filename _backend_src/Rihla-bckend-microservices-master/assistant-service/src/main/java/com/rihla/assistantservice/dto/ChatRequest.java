package com.rihla.assistantservice.dto;

import lombok.Data;

@Data
public class ChatRequest {
    private String userId;
    private String message;
}
