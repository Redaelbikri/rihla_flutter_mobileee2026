package com.rihla.itineraryservice.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.util.List;

public record ItineraryRequest(
        @NotBlank String fromCity,
        @NotBlank String toCity,
        @NotNull LocalDate startDate,
        @NotNull LocalDate endDate,
        List<String> interests,
        Double maxEventPrice,
        Double maxNightPrice,
        String transportType,       // TRAIN / BUS (must match your transport enum values)
        Integer limitPerDay         // default 3
) {}
