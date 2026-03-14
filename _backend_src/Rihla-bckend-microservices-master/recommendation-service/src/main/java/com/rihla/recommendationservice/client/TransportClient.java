package com.rihla.recommendationservice.client;

import com.rihla.recommendationservice.dto.TripResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.time.LocalDate;
import java.util.List;

@FeignClient(name = "transport-service")
public interface TransportClient {

    @GetMapping("/api/transports/trips/search")
    List<TripResponse> search(
            @RequestParam String fromCity,
            @RequestParam String toCity,
            @RequestParam LocalDate date,
            @RequestParam String type
    );
}
