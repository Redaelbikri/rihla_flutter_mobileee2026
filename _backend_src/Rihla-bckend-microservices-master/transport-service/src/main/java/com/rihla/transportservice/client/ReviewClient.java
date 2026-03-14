package com.rihla.transportservice.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "review-service")
public interface ReviewClient {

    @GetMapping("/reviews/TRANSPORT/{tripId}/stats")
    RatingStatsResponse stats(@PathVariable("tripId") String tripId);

    record RatingStatsResponse(long count, double average) {}
}
