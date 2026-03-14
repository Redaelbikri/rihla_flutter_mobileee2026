package com.rihla.recommendationservice.service;

import com.rihla.recommendationservice.client.EventClient;
import com.rihla.recommendationservice.client.HebergementClient;
import com.rihla.recommendationservice.client.TransportClient;
import com.rihla.recommendationservice.dto.EventResponse;
import com.rihla.recommendationservice.dto.HebergementResponse;
import com.rihla.recommendationservice.dto.RecommendationResponse;
import com.rihla.recommendationservice.dto.TripResponse;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class RecommendationService {

    private final EventClient eventClient;
    private final TransportClient transportClient;
    private final HebergementClient hebergementClient;

    public RecommendationService(EventClient eventClient,
                                 TransportClient transportClient,
                                 HebergementClient hebergementClient) {
        this.eventClient = eventClient;
        this.transportClient = transportClient;
        this.hebergementClient = hebergementClient;
    }

    public RecommendationResponse recommend(
            String city,
            String category,
            Double maxEventPrice,
            String fromCity,
            String toCity,
            String date,
            String transportType,
            Double maxNightPrice,
            Integer limit
    ) {
        int lim = (limit == null || limit < 1) ? 8 : Math.min(limit, 20);

        List<EventResponse> events = fetchEvents(city, category, maxEventPrice, lim);
        List<TripResponse> trips = fetchTrips(fromCity, toCity, date, transportType, lim);
        List<HebergementResponse> hebergements = fetchHebergements(city, maxNightPrice, lim);

        return new RecommendationResponse(events, trips, hebergements);
    }

    private List<EventResponse> fetchEvents(String city, String category, Double maxPrice, int limit) {
        try {
            List<EventResponse> base = (city != null && !city.isBlank())
                    ? eventClient.filterByCity(city)
                    : eventClient.getAll();

            if (category != null && !category.isBlank()) {
                List<EventResponse> byCat = eventClient.filterByCategory(category);
                Set<String> catIds = byCat.stream()
                        .map(EventResponse::getId)
                        .collect(Collectors.toSet());

                base = base.stream()
                        .filter(e -> e.getId() != null && catIds.contains(e.getId()))
                        .toList();
            }

            if (maxPrice != null) {
                base = base.stream()
                        .filter(e -> e.getPrix() != null && e.getPrix() <= maxPrice)
                        .toList();
            }

            return base.stream().limit(limit).toList();
        } catch (Exception ex) {
            return List.of();
        }
    }

    private List<TripResponse> fetchTrips(String fromCity, String toCity, String date, String transportType, int limit) {
        try {
            if (fromCity == null || toCity == null || date == null || transportType == null) return List.of();
            if (fromCity.isBlank() || toCity.isBlank() || date.isBlank() || transportType.isBlank()) return List.of();

            LocalDate d = LocalDate.parse(date); // ✅ conversion
            List<TripResponse> trips = transportClient.search(fromCity, toCity, d, transportType);

            return trips.stream().limit(limit).toList();
        } catch (Exception ex) {
            return List.of();
        }
    }

    private List<HebergementResponse> fetchHebergements(String city, Double maxNightPrice, int limit) {
        try {
            List<HebergementResponse> list = hebergementClient.search(
                    (city == null || city.isBlank()) ? null : city,
                    maxNightPrice
            );
            return list.stream().limit(limit).toList();
        } catch (Exception ex) {
            return List.of();
        }
    }
}
