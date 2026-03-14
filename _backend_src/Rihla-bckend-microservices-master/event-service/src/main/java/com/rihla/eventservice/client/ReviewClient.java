package com.rihla.eventservice.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "review-service")
public interface ReviewClient {

    @GetMapping("/reviews/EVENT/{eventId}/stats")
    RatingStatsResponse statsForEvent(@PathVariable("eventId") String eventId);

    record RatingStatsResponse(long count, double average) {}
}
