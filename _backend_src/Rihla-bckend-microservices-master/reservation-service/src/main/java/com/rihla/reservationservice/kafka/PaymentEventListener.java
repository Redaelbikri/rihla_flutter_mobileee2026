package com.rihla.reservationservice.kafka;

import com.rihla.reservationservice.service.ReservationService;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
public class PaymentEventListener {

    private final ReservationService reservationService;

    public PaymentEventListener(ReservationService reservationService) {
        this.reservationService = reservationService;
    }

    @KafkaListener(topics = "payment.events", groupId = "reservation-service")
    public void consume(DomainEvent evt) {
        if (evt == null || evt.getEventId() == null || evt.getEventId().isBlank()) return;

        String type = String.valueOf(evt.getEventType());
        switch (type) {
            case "PAYMENT_SUCCEEDED" -> reservationService.onPaymentSucceeded(evt.getEventId());
            case "PAYMENT_FAILED" -> reservationService.onPaymentFailed(evt.getEventId());
            default -> { /* ignore */ }
        }
    }
}
