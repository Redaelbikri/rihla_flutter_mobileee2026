package com.rihla.recommendationservice.client;

import com.rihla.recommendationservice.dto.EventResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@FeignClient(name = "event-service")
public interface EventClient {

    @GetMapping("/api/events")
    List<EventResponse> getAll();

    @GetMapping("/api/events/filter/city")
    List<EventResponse> filterByCity(@RequestParam("city") String city);

    @GetMapping("/api/events/filter/category")
    List<EventResponse> filterByCategory(@RequestParam("category") String category);
}
