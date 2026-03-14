package com.rihla.reservationservice.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.*;

@FeignClient(name = "event-service")
public interface EventClient {

    @GetMapping("/api/events/{id}/check")
    Boolean check(@PathVariable("id") String id, @RequestParam("quantity") int quantity);

    @PutMapping("/api/events/internal/{id}/reduce-stock")
    void reduceInternal(@PathVariable("id") String id, @RequestParam("quantity") int quantity);
}
