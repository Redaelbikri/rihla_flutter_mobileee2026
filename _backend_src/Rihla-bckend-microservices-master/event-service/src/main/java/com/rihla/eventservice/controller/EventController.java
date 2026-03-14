package com.rihla.eventservice.controller;

import com.rihla.eventservice.client.ReviewClient;
import com.rihla.eventservice.dto.EventDetailsResponse;
import com.rihla.eventservice.dto.EventRequest;
import com.rihla.eventservice.dto.EventResponse;
import com.rihla.eventservice.service.EventService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/events")
public class EventController {

    private final EventService eventService;
    private final ReviewClient reviewClient;

    public EventController(EventService eventService, ReviewClient reviewClient) {
        this.eventService = eventService;
        this.reviewClient = reviewClient;
    }



    @PostMapping
    public ResponseEntity<EventResponse> create(@Valid @RequestBody EventRequest request) {
        return ResponseEntity.ok(eventService.createEvent(request));
    }

    @GetMapping
    public ResponseEntity<List<EventResponse>> getAll() {
        return ResponseEntity.ok(eventService.getAllEvents());
    }

    @GetMapping("/{id}")
    public ResponseEntity<EventResponse> getById(@PathVariable String id) {
        return ResponseEntity.ok(eventService.getEventById(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<EventResponse> update(@PathVariable String id, @Valid @RequestBody EventRequest request) {
        return ResponseEntity.ok(eventService.updateEvent(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        eventService.deleteEvent(id);
        return ResponseEntity.noContent().build();
    }


    @GetMapping("/search")
    public ResponseEntity<List<EventResponse>> search(@RequestParam("keyword") String keyword) {
        return ResponseEntity.ok(eventService.searchEvents(keyword));
    }

    @GetMapping("/filter/category")
    public ResponseEntity<List<EventResponse>> filterByCategory(@RequestParam("category") String category) {
        return ResponseEntity.ok(eventService.filterByCategory(category));
    }

    @GetMapping("/filter/city")
    public ResponseEntity<List<EventResponse>> filterByCity(@RequestParam("city") String city) {
        return ResponseEntity.ok(eventService.filterByCity(city));
    }



    @PostMapping("/{id}/stock/decrease")
    public ResponseEntity<Void> decreaseStock(@PathVariable String id, @RequestParam("quantity") int quantity) {
        eventService.decreaseStock(id, quantity);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/availability")
    public ResponseEntity<Boolean> checkAvailability(@PathVariable String id, @RequestParam("quantity") int quantity) {
        return ResponseEntity.ok(eventService.checkAvailability(id, quantity));
    }



    @GetMapping("/{id}/details")
    public ResponseEntity<EventDetailsResponse> details(@PathVariable String id) {
        EventResponse event = eventService.getEventById(id);
        ReviewClient.RatingStatsResponse stats = reviewClient.statsForEvent(id);

        return ResponseEntity.ok(new EventDetailsResponse(
                event,
                stats.count(),
                stats.average()
        ));
    }
}
