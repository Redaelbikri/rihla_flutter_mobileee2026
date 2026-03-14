package com.rihla.userservice.otp;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Data
@Document("otp_records")
public class OtpRecord {

    @Id
    private String id;

    private String email;

    private String code;

    private OtpType type;

    private LocalDateTime createdAt;

    @Indexed(expireAfterSeconds = 0)
    private LocalDateTime expiresAt;

    private boolean used = false;
}
