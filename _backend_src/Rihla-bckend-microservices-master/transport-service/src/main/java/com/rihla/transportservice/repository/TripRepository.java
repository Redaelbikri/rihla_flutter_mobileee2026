package com.rihla.transportservice.repository;

import com.rihla.transportservice.entity.TransportType;
import com.rihla.transportservice.entity.Trip;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface TripRepository extends MongoRepository<Trip, String> {

    List<Trip> findByFromCityIgnoreCaseAndToCityIgnoreCaseAndTypeAndDepartureAtBetween(
            String fromCity,
            String toCity,
            TransportType type,
            LocalDateTime start,
            LocalDateTime end
    );

    List<Trip> findByType(TransportType type);
}
