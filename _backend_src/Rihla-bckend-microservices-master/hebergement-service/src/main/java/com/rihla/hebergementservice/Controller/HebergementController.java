package com.rihla.hebergementservice.Controller;

import com.rihla.hebergementservice.client.ReviewClient;
import com.rihla.hebergementservice.dto.HebergementRequest;
import com.rihla.hebergementservice.dto.HebergementResponse;
import com.rihla.hebergementservice.entity.HebergementType;
import com.rihla.hebergementservice.Service.HebergementService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/hebergements")
public class HebergementController {

    private final HebergementService service;
    private final ReviewClient reviewClient;

    public HebergementController(HebergementService service, ReviewClient reviewClient) {
        this.service = service;
        this.reviewClient = reviewClient;
    }

    @GetMapping
    public List<HebergementResponse> all(
            @RequestParam(required = false) String city,
            @RequestParam(required = false) Double maxPrice
    ) {
        return service.search(city, maxPrice);
    }

    @GetMapping("/{id}")
    public ResponseEntity<HebergementResponse> byId(@PathVariable String id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @GetMapping("/filter/type/{type}")
    public List<HebergementResponse> byType(@PathVariable HebergementType type) {
        return service.filterByType(type);
    }

    @PostMapping
    public ResponseEntity<HebergementResponse> create(@Valid @RequestBody HebergementRequest req) {
        return ResponseEntity.ok(service.create(req));
    }

    @PutMapping("/internal/{id}/reduce-stock")
    public ResponseEntity<String> reduceStockInternal(@PathVariable String id, @RequestParam int quantity) {
        service.reduceStock(id, quantity);
        return ResponseEntity.ok("Stock reduced (internal)");
    }

    @PutMapping("/{id}")
    public ResponseEntity<HebergementResponse> update(@PathVariable String id, @Valid @RequestBody HebergementRequest req) {
        return ResponseEntity.ok(service.update(id, req));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}/reduce-stock")
    public ResponseEntity<String> reduceStock(@PathVariable String id, @RequestParam int quantity) {
        service.reduceStock(id, quantity);
        return ResponseEntity.ok("Stock updated successfully");
    }

    @GetMapping("/{id}/check")
    public ResponseEntity<Boolean> check(@PathVariable String id, @RequestParam int quantity) {
        return ResponseEntity.ok(service.checkAvailability(id, quantity));
    }


    @GetMapping("/{id}/rating-stats")
    public ResponseEntity<ReviewClient.RatingStatsResponse> ratingStats(@PathVariable String id) {
        return ResponseEntity.ok(reviewClient.statsForHebergement(id));
    }
}
