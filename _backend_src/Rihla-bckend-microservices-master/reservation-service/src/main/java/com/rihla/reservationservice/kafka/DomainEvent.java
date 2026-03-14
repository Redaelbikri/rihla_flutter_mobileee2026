package com.rihla.reservationservice.kafka;

import lombok.*;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DomainEvent {
    public String eventId;
    public String eventType;     // RESERVATION_CONFIRMED
    public String userSubject;   // email
    public String message;
    public LocalDateTime createdAt;
}
