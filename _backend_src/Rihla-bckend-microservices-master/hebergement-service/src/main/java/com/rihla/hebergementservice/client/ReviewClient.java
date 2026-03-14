package com.rihla.hebergementservice.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "review-service")
public interface ReviewClient {
    @GetMapping("/api/reviews/ACCOMMODATION/{hebergementId}/stats")
    RatingStatsResponse statsForHebergement(@PathVariable("hebergementId") String hebergementId);
    record RatingStatsResponse(long count, double average) {}
}
