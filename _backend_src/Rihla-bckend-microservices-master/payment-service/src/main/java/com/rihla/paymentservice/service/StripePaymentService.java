package com.rihla.paymentservice.service;

import com.rihla.paymentservice.entity.Payment;
import com.rihla.paymentservice.repository.PaymentRepository;
import com.stripe.model.PaymentIntent;
import com.stripe.param.PaymentIntentCreateParams;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Service
public class StripePaymentService {

    private final PaymentRepository repo;

    public StripePaymentService(PaymentRepository repo) {
        this.repo = repo;
    }

    public Map<String, Object> createPaymentIntent(String userSubject, String reservationId, long amountMad) throws Exception {

        long amountMinor = amountMad * 100; // MAD -> centimes

        PaymentIntentCreateParams params =
                PaymentIntentCreateParams.builder()
                        .setAmount(amountMinor)
                        .setCurrency("mad")
                        .putMetadata("reservationId", reservationId)
                        .putMetadata("userSubject", userSubject)
                        .build();

        PaymentIntent intent = PaymentIntent.create(params);

        Payment p = Payment.builder()
                .userSubject(userSubject)
                .reservationId(reservationId)
                .paymentIntentId(intent.getId())
                .amount(amountMinor)
                .currency("mad")
                .status("CREATED")
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        repo.save(p);

        return Map.of(
                "paymentIntentId", intent.getId(),
                "clientSecret", intent.getClientSecret()
        );
    }

    public List<Payment> myPayments(String userSubject) {
        return repo.findByUserSubjectOrderByCreatedAtDesc(userSubject);
    }
}
