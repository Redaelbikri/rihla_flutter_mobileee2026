package com.rihla.itineraryservice.dto;

import java.time.LocalDate;
import java.util.List;

public record ItineraryResponse(
        String fromCity,
        String toCity,
        LocalDate startDate,
        LocalDate endDate,
        String aiSummary,
        List<DayPlan> days
) {}
