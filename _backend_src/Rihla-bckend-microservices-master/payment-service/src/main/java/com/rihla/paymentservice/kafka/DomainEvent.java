package com.rihla.paymentservice.kafka;

import lombok.*;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DomainEvent {
    public String eventId;
    public String eventType;     // PAYMENT_SUCCEEDED / PAYMENT_FAILED
    public String userSubject;
    public String message;
    public LocalDateTime createdAt;
}
