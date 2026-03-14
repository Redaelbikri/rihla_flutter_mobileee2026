package com.rihla.paymentservice.controller;

import com.rihla.paymentservice.service.StripePaymentService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/payments")
public class PaymentController {

    private final StripePaymentService stripe;

    public PaymentController(StripePaymentService stripe) {
        this.stripe = stripe;
    }

    public static class CreateIntentRequest {
        @NotBlank public String reservationId;
        @Positive public long amountMad; // MAD in whole units (e.g. 250)
    }

    @PostMapping("/create-intent")
    public Map<String, Object> createIntent(@Valid @RequestBody CreateIntentRequest req, Authentication auth) throws Exception {
        return stripe.createPaymentIntent(auth.getName(), req.reservationId, req.amountMad);
    }

    @GetMapping("/me")
    public java.util.List<?> my(Authentication auth) {
        return stripe.myPayments(auth.getName());
    }
}
