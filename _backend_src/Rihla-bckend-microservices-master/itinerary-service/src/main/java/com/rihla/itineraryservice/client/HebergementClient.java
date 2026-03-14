package com.rihla.itineraryservice.client;

import com.rihla.itineraryservice.dto.remote.HebergementResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@FeignClient(name = "hebergement-service")
public interface HebergementClient {

    @GetMapping("/api/hebergements")
    List<HebergementResponse> search(
            @RequestParam(value = "city", required = false) String city,
            @RequestParam(value = "maxPrice", required = false) Double maxPrice
    );
}
