package com.rihla.recommendationservice.controller;

import com.rihla.recommendationservice.dto.RecommendationResponse;
import com.rihla.recommendationservice.service.RecommendationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/recommendations")
public class RecommendationController {

    private final RecommendationService service;

    public RecommendationController(RecommendationService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<RecommendationResponse> recommend(
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Double maxEventPrice,

            @RequestParam(required = false) String fromCity,
            @RequestParam(required = false) String toCity,
            @RequestParam(required = false) String date,
            @RequestParam(required = false) String transportType,

            @RequestParam(required = false) Double maxNightPrice,
            @RequestParam(required = false) Integer limit
    ) {
        return ResponseEntity.ok(
                service.recommend(city, category, maxEventPrice, fromCity, toCity, date, transportType, maxNightPrice, limit)
        );
    }
}
