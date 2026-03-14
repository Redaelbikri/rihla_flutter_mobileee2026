package com.rihla.transportservice.entity;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.math.BigDecimal;
import java.time.LocalDateTime;
@Data
@Document("trips")
public class Trip {

    @Id
    private String id;

    @Indexed
    private String fromCity;

    @Indexed
    private String toCity;

    @Indexed
    private LocalDateTime departureAt;

    private LocalDateTime arrivalAt;

    @Indexed
    private TransportType type;

    private BigDecimal price;
    private String currency;

    private int capacity;
    private int availableSeats;

    private String providerName;

}
