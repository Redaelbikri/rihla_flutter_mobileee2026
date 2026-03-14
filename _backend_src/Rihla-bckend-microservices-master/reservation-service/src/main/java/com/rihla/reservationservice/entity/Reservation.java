package com.rihla.reservationservice.entity;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Data
@Document("reservations")
public class Reservation {

    @Id
    private String id;

    // (email)
    private String userSubject;

    private ReservationStatus status;
    private String paymentStatus;
    private LocalDateTime createdAt;

    private String transportTripId;
    private Integer transportSeats;

    private String hebergementId;
    private Integer hebergementRooms;

    private String eventId;
    private Integer eventTickets;
}
