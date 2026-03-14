package com.rihla.transportservice.dto;

import com.rihla.transportservice.entity.TransportType;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class TripResponse {
    public String id;
    public String fromCity;
    public String toCity;
    public LocalDateTime departureAt;
    public LocalDateTime arrivalAt;
    public TransportType type;
    public BigDecimal price;
    public String currency;
    public int capacity;
    public int availableSeats;
    public String providerName;
}
