package com.rihla.reservationservice.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.*;

@FeignClient(name = "transport-service")
public interface TransportClient {

    @GetMapping("/api/transports/trips/{id}/check")
    Boolean check(@PathVariable("id") String tripId, @RequestParam("quantity") int quantity);


    @PutMapping("/api/transports/internal/trips/{id}/reduce-seats")
    void reduceInternal(@PathVariable("id") String tripId, @RequestParam("quantity") int quantity);
}
