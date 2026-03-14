package com.rihla.itineraryservice.dto.remote;

import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class TripResponse {
    public String id;
    public String fromCity;
    public String toCity;
    public LocalDateTime departureAt;
    public LocalDateTime arrivalAt;
    public String type;            // was enum in transport-service
    public BigDecimal price;
    public String currency;
    public int capacity;
    public int availableSeats;
    public String providerName;
}
