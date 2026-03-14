package com.rihla.itineraryservice.dto;

import java.util.List;

public record MapRoute(
        String provider,                // "OSRM"
        double distanceKm,
        double durationMin,
        List<List<Double>> coordinates  // GeoJSON: [ [lng,lat], ... ]
) {}
