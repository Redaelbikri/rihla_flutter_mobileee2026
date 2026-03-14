package com.rihla.reservationservice.DTO;

import java.time.LocalDateTime;

public class ReservationResponse {
    public String id;
    public String userSubject;
    public String status;
    public LocalDateTime createdAt;

    public String transportTripId;
    public Integer transportSeats;

    public String hebergementId;
    public Integer hebergementRooms;

    public String eventId;
    public Integer eventTickets;
}
