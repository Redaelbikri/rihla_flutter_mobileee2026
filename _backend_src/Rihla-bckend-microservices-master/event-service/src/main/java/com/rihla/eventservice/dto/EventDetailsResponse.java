package com.rihla.eventservice.dto;

public record EventDetailsResponse(
        EventResponse event,
        long reviewCount,
        double averageRating
) {}
