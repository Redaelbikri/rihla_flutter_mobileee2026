package com.rihla.reservationservice.kafka;

import lombok.RequiredArgsConstructor;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ReservationEventProducer {

    private final KafkaTemplate<String, DomainEvent> kafkaTemplate;

    public void publishConfirmed(DomainEvent evt) {

        kafkaTemplate.send("reservation.events", evt.eventId, evt);
    }
}
