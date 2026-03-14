package com.rihla.paymentservice.repository;

import com.rihla.paymentservice.entity.Payment;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Optional;

public interface PaymentRepository extends MongoRepository<Payment, String> {
    List<Payment> findByUserSubjectOrderByCreatedAtDesc(String userSubject);
    Optional<Payment> findByPaymentIntentId(String paymentIntentId);
}
