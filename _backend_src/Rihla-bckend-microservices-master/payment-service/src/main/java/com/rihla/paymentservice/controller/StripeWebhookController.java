package com.rihla.paymentservice.controller;

import com.rihla.paymentservice.entity.Payment;
import com.rihla.paymentservice.kafka.DomainEvent;
import com.rihla.paymentservice.kafka.PaymentEventProducer;
import com.rihla.paymentservice.repository.PaymentRepository;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.model.Event;
import com.stripe.model.PaymentIntent;
import com.stripe.net.Webhook;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StreamUtils;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.Optional;

@RestController
@RequestMapping("/api/payments")
public class StripeWebhookController {

    @Value("${stripe.webhookSecret:}")
    private String webhookSecret;

    private final PaymentRepository repo;
    private final PaymentEventProducer producer;

    public StripeWebhookController(PaymentRepository repo, PaymentEventProducer producer) {
        this.repo = repo;
        this.producer = producer;
    }

    @PostMapping("/webhook")
    public ResponseEntity<String> handleWebhook(
            HttpServletRequest request,
            @RequestHeader(value = "Stripe-Signature", required = false) String sigHeader
    ) throws Exception {

        if (sigHeader == null || sigHeader.isBlank()) {
            return ResponseEntity.badRequest().body("missing Stripe-Signature");
        }
        if (webhookSecret == null || webhookSecret.isBlank()) {
            return ResponseEntity.internalServerError().body("webhook secret not configured");
        }

        String payload = StreamUtils.copyToString(request.getInputStream(), StandardCharsets.UTF_8);

        Event event;
        try {
            event = Webhook.constructEvent(payload, sigHeader, webhookSecret);
        } catch (SignatureVerificationException e) {
            return ResponseEntity.badRequest().body("invalid signature");
        }

        switch (event.getType()) {
            case "payment_intent.succeeded" -> handleSucceeded(event);
            case "payment_intent.payment_failed" -> handleFailed(event);
            default -> { /* ignore */ }
        }

        return ResponseEntity.ok("ok");
    }

    private void handleSucceeded(Event event) {
        PaymentIntent intent = (PaymentIntent) event.getDataObjectDeserializer()
                .getObject()
                .orElse(null);

        if (intent == null) return;

        Optional<Payment> opt = repo.findByPaymentIntentId(intent.getId());
        if (opt.isEmpty()) return;

        Payment p = opt.get();
        p.setStatus("SUCCEEDED");
        p.setUpdatedAt(LocalDateTime.now());
        repo.save(p);

        DomainEvent evt = DomainEvent.builder()
                .eventId(p.getReservationId())
                .eventType("PAYMENT_SUCCEEDED")
                .userSubject(p.getUserSubject())
                .message("Payment succeeded for reservation " + p.getReservationId())
                .createdAt(LocalDateTime.now())
                .build();

        try { producer.publish(evt); } catch (Exception ignored) {}
    }

    private void handleFailed(Event event) {
        PaymentIntent intent = (PaymentIntent) event.getDataObjectDeserializer()
                .getObject()
                .orElse(null);

        if (intent == null) return;

        Optional<Payment> opt = repo.findByPaymentIntentId(intent.getId());
        if (opt.isEmpty()) return;

        Payment p = opt.get();
        p.setStatus("FAILED");
        p.setUpdatedAt(LocalDateTime.now());
        repo.save(p);

        DomainEvent evt = DomainEvent.builder()
                .eventId(p.getReservationId())
                .eventType("PAYMENT_FAILED")
                .userSubject(p.getUserSubject())
                .message("Payment failed for reservation " + p.getReservationId())
                .createdAt(LocalDateTime.now())
                .build();

        try { producer.publish(evt); } catch (Exception ignored) {}
    }
}
