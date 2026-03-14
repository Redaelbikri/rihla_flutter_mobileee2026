package com.rihla.itineraryservice.dto;

import com.rihla.itineraryservice.dto.remote.EventResponse;
import com.rihla.itineraryservice.dto.remote.HebergementResponse;
import com.rihla.itineraryservice.dto.remote.TripResponse;

import java.time.LocalDate;
import java.util.List;

public record DayPlan(
        LocalDate date,
        HebergementResponse hebergement,
        List<EventResponse> events,
        List<TripResponse> transports,
        String aiNarrative,
        List<PlaceOnMap> markers,
        List<MapRoute> routes
) {}
