package com.rihla.itineraryservice.repo;

import com.rihla.itineraryservice.entity.Itinerary;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface ItineraryRepository extends MongoRepository<Itinerary, String> {
    List<Itinerary> findByUserIdOrderByCreatedAtDesc(String userId);
}
