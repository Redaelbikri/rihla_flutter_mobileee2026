package com.rihla.reservationservice.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.*;

@FeignClient(name = "hebergement-service")
public interface HebergementClient {

    @GetMapping("/api/hebergements/{id}/check")
    Boolean check(@PathVariable("id") String id, @RequestParam("quantity") int quantity);

    @PutMapping("/api/hebergements/internal/{id}/reduce-stock")
    void reduceInternal(@PathVariable("id") String id, @RequestParam("quantity") int quantity);
}
