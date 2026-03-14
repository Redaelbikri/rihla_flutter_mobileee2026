package com.rihla.itineraryservice.client;

import com.rihla.itineraryservice.dto.remote.EventResponse;
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
}
