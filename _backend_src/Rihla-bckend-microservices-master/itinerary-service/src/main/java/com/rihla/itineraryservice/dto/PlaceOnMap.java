package com.rihla.itineraryservice.dto;

public record PlaceOnMap(
        String type,     // CITY | HEBERGEMENT | EVENT
        String refId,
        String title,
        String address,
        GeoPoint location
) {}
