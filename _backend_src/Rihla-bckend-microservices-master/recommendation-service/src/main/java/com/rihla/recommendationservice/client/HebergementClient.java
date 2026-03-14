package com.rihla.recommendationservice.client;

import com.rihla.recommendationservice.dto.HebergementResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;

@FeignClient(name = "hebergement-service")
public interface HebergementClient {

    @GetMapping("/api/hebergements")
    List<HebergementResponse> search(
            @RequestParam(required = false) String city,
            @RequestParam(required = false) Double maxPrice
    );
}
