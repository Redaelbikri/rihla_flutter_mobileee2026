package com.rihla.transportservice.dto;

import com.rihla.transportservice.entity.TransportType;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class TripRequest {

    @NotBlank
    public String fromCity;

    @NotBlank
    public String toCity;

    @NotNull
    public LocalDateTime departureAt;

    @NotNull
    public LocalDateTime arrivalAt;

    @NotNull
    public TransportType type;

    @NotNull
    @DecimalMin("0.0")
    public BigDecimal price;

    @NotBlank
    public String currency;

    @Min(1)
    public int capacity;

    @NotBlank
    public String providerName;
}
