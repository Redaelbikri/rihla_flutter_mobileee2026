package com.rihla.itineraryservice.entity;

import com.rihla.itineraryservice.dto.ItineraryResponse;
import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Document(collection = "itineraries")
public class Itinerary {

    @Id
    private String id;

    private String userId; // from JWT subject
    private LocalDateTime createdAt;

    private ItineraryResponse payload; // store full response JSON
}
