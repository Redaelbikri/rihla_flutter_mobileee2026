package com.rihla.notificationservice.dto;

import lombok.Data;

import java.time.Instant;

@Data
public class NotificationResponse {
    private String id;
    private String type;
    private String title;
    private String message;
    private boolean read;
    private Instant createdAt;
}
