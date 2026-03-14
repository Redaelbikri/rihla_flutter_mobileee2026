package com.rihla.paymentservice.entity;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document("payments")
public class Payment {
    @Id
    private String id;

    private String userSubject;       // email
    private String reservationId;

    private String paymentIntentId;
    private Long amount;
    private String currency;          // "mad"

    private String status;            // CREATED / SUCCEEDED / FAILED
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
