package com.rihla.recommendationservice.dto;

import lombok.Data;

import java.util.List;

@Data
public class RecommendationResponse {
    private List<EventResponse> events;
    private List<TripResponse> trips;
    private List<HebergementResponse> hebergements;

    public RecommendationResponse(List<EventResponse> events,
                                  List<TripResponse> trips,
                                  List<HebergementResponse> hebergements) {
        this.events = events;
        this.trips = trips;
        this.hebergements = hebergements;
    }
}
