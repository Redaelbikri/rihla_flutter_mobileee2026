package com.rihla.itineraryservice.controller;

import com.rihla.itineraryservice.dto.ItineraryRequest;
import com.rihla.itineraryservice.dto.ItineraryResponse;
import com.rihla.itineraryservice.entity.Itinerary;
import com.rihla.itineraryservice.service.ItineraryOrchestratorService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/itineraries")
public class ItineraryController {

    private final ItineraryOrchestratorService service;

    public ItineraryController(ItineraryOrchestratorService service) {
        this.service = service;
    }

    @PostMapping("/generate")
    public ResponseEntity<ItineraryResponse> generate(@Valid @RequestBody ItineraryRequest req) {
        return ResponseEntity.ok(service.generate(req));
    }

    @GetMapping("/me")
    public ResponseEntity<List<Itinerary>> myItineraries() {
        return ResponseEntity.ok(service.myItineraries());
    }
}
