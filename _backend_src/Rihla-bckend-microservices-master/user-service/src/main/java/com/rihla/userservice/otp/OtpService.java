package com.rihla.userservice.otp;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;

@Service
public class OtpService {

    private final OtpRepository otpRepository;
    private final SecureRandom secureRandom = new SecureRandom();

    @Value("${rihla.otp.expiry-minutes:10}")
    private int expiryMinutes;

    public OtpService(OtpRepository otpRepository) {
        this.otpRepository = otpRepository;
    }

    /**
     * Generates a new 6-digit OTP, invalidates any existing unused OTPs of the same type,
     * persists it, and returns the code so the caller can email it.
     */
    public String generateAndSave(String email, OtpType type) {
        // Invalidate previous OTPs for this email+type
        otpRepository.deleteAllByEmailAndType(email, type);

        String code = String.format("%06d", secureRandom.nextInt(1_000_000));

        OtpRecord record = new OtpRecord();
        record.setEmail(email);
        record.setCode(code);
        record.setType(type);
        record.setCreatedAt(LocalDateTime.now());
        record.setExpiresAt(LocalDateTime.now().plusMinutes(expiryMinutes));
        record.setUsed(false);

        otpRepository.save(record);
        return code;
    }

    /**
     * Validates the OTP. Returns true and marks it as used if valid;
     * returns false if not found, expired, or already used.
     */
    public boolean validate(String email, OtpType type, String code) {
        return otpRepository
                .findTopByEmailAndTypeAndUsedFalseOrderByCreatedAtDesc(email, type)
                .filter(r -> !r.getExpiresAt().isBefore(LocalDateTime.now()))
                .filter(r -> r.getCode().equals(code))
                .map(r -> {
                    r.setUsed(true);
                    otpRepository.save(r);
                    return true;
                })
                .orElse(false);
    }
}
