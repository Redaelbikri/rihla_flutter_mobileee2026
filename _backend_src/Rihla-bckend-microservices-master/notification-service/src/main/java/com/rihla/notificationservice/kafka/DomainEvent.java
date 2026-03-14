package com.rihla.notificationservice.kafka;

import java.time.Instant;

public record DomainEvent(
        String eventId,
        String eventType,
        String userSubject,
        String title,
        String message

){}