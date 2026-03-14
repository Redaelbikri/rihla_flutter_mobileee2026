package com.rihla.userservice.otp;

import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface OtpRepository extends MongoRepository<OtpRecord, String> {

    Optional<OtpRecord> findTopByEmailAndTypeAndUsedFalseOrderByCreatedAtDesc(String email, OtpType type);

    void deleteAllByEmailAndType(String email, OtpType type);
}
