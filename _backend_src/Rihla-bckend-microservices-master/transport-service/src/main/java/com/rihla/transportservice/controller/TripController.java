package com.rihla.transportservice.controller;

import com.rihla.transportservice.client.ReviewClient;
import com.rihla.transportservice.dto.TripRequest;
import com.rihla.transportservice.dto.TripResponse;
import com.rihla.transportservice.entity.TransportType;
import com.rihla.transportservice.service.TripService;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@AllArgsConstructor
@RestController
@RequestMapping("/api/transports")
public class TripController {

    private final TripService service;
    private final ReviewClient reviewClient;

    @GetMapping("/trips/search")
    public List<TripResponse> search(
            @RequestParam String fromCity,
            @RequestParam String toCity,
            @RequestParam LocalDate date,
            @RequestParam TransportType type
    ) {
        return service.search(fromCity, toCity, date, type);
    }

    @GetMapping("/trips/{id}")
    public ResponseEntity<TripResponse> byId(@PathVariable String id) {
        return ResponseEntity.ok(service.getById(id));
    }

    // ✅ NEW: rating stats for this trip
    @GetMapping("/trips/{id}/rating-stats")
    public ResponseEntity<ReviewClient.RatingStatsResponse> ratingStats(@PathVariable String id) {
        return ResponseEntity.ok(reviewClient.stats(id));
    }

    @GetMapping("/trips/filter/type/{type}")
    public List<TripResponse> byType(@PathVariable TransportType type) {
        return service.filterByType(type);
    }

    @PostMapping("/trips")
    public ResponseEntity<TripResponse> create(@Valid @RequestBody TripRequest req) {
        return ResponseEntity.ok(service.create(req));
    }

    @PutMapping("/trips/{id}")
    public ResponseEntity<TripResponse> update(@PathVariable String id, @Valid @RequestBody TripRequest req) {
        return ResponseEntity.ok(service.update(id, req));
    }

    @DeleteMapping("/trips/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/trips/{id}/reduce-seats")
    public ResponseEntity<String> reduceSeats(@PathVariable String id, @RequestParam int quantity) {
        service.reduceSeats(id, quantity);
        return ResponseEntity.ok("Seats updated successfully");
    }

    @PutMapping("/internal/trips/{id}/reduce-seats")
    public ResponseEntity<String> reduceSeatsInternal(@PathVariable String id, @RequestParam int quantity) {
        service.reduceSeats(id, quantity);
        return ResponseEntity.ok("Seats updated successfully (internal)");
    }

    @GetMapping("/trips/{id}/check")
    public ResponseEntity<Boolean> check(@PathVariable String id, @RequestParam int quantity) {
        return ResponseEntity.ok(service.checkAvailability(id, quantity));
    }
}
