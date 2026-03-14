package com.rihla.itineraryservice.maps;

import com.rihla.itineraryservice.dto.GeoPoint;
import com.rihla.itineraryservice.dto.MapRoute;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class MapProviderService {

    private final RestTemplate restTemplate = new RestTemplate();
    private final Map<String, GeoPoint> cache = new ConcurrentHashMap<>();

    @Value("${osm.nominatim.baseUrl}")
    private String nominatimBaseUrl;

    @Value("${osm.userAgent}")
    private String userAgent;

    @Value("${osrm.baseUrl}")
    private String osrmBaseUrl;

    public GeoPoint geocode(String address) {
        if (address == null || address.isBlank()) return null;

        return cache.computeIfAbsent(address.trim(), key -> {
            try {
                String url = UriComponentsBuilder.fromHttpUrl(nominatimBaseUrl)
                        .path("/search")
                        .queryParam("q", key)
                        .queryParam("format", "json")
                        .queryParam("limit", "1")
                        .build(true)
                        .toUriString();

                HttpHeaders h = new HttpHeaders();
                h.set("User-Agent", userAgent);
                h.setAccept(List.of(MediaType.APPLICATION_JSON));
                HttpEntity<Void> entity = new HttpEntity<>(h);

                ResponseEntity<List> resp = restTemplate.exchange(url, HttpMethod.GET, entity, List.class);
                List<?> body = resp.getBody();
                if (body == null || body.isEmpty()) return null;

                Map<?, ?> first = (Map<?, ?>) body.get(0);
                String lat = String.valueOf(first.get("lat"));
                String lon = String.valueOf(first.get("lon"));

                return new GeoPoint(Double.parseDouble(lat), Double.parseDouble(lon));
            } catch (Exception e) {
                return null;
            }
        });
    }

    public MapRoute route(GeoPoint a, GeoPoint b) {
        if (a == null || b == null) return null;

        try {
            String url = osrmBaseUrl + "/route/v1/driving/"
                    + a.lng() + "," + a.lat() + ";"
                    + b.lng() + "," + b.lat()
                    + "?overview=full&geometries=geojson";

            ResponseEntity<Map> resp = restTemplate.getForEntity(url, Map.class);
            Map body = resp.getBody();
            if (body == null) return null;

            List routes = (List) body.get("routes");
            if (routes == null || routes.isEmpty()) return null;

            Map r0 = (Map) routes.get(0);
            double distKm = ((Number) r0.getOrDefault("distance", 0)).doubleValue() / 1000.0;
            double durMin = ((Number) r0.getOrDefault("duration", 0)).doubleValue() / 60.0;

            Map geom = (Map) r0.get("geometry");
            List<List<Double>> coords = geom == null ? List.of() : (List<List<Double>>) geom.get("coordinates");

            return new MapRoute("OSRM", round2(distKm), round1(durMin), coords == null ? List.of() : coords);
        } catch (Exception e) {
            return null;
        }
    }

    private double round2(double v) { return Math.round(v * 100.0) / 100.0; }
    private double round1(double v) { return Math.round(v * 10.0) / 10.0; }
}
