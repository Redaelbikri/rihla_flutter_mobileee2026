package com.rihla.itineraryservice.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rihla.itineraryservice.ai.GroqClient;
import com.rihla.itineraryservice.client.EventClient;
import com.rihla.itineraryservice.client.HebergementClient;
import com.rihla.itineraryservice.client.TransportClient;
import com.rihla.itineraryservice.dto.*;
import com.rihla.itineraryservice.dto.remote.EventResponse;
import com.rihla.itineraryservice.dto.remote.HebergementResponse;
import com.rihla.itineraryservice.dto.remote.TripResponse;
import com.rihla.itineraryservice.entity.Itinerary;
import com.rihla.itineraryservice.maps.MapProviderService;
import com.rihla.itineraryservice.repo.ItineraryRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class ItineraryOrchestratorService {

    private final EventClient eventClient;
    private final HebergementClient hebergementClient;
    private final TransportClient transportClient;
    private final GroqClient groq;
    private final MapProviderService maps;


    private final ItineraryRepository repo;

    private final ObjectMapper mapper = new ObjectMapper();


    public ItineraryOrchestratorService(EventClient eventClient,
                                        HebergementClient hebergementClient,
                                        TransportClient transportClient,
                                        GroqClient groq,
                                        MapProviderService maps,
                                        ItineraryRepository repo) {
        this.eventClient = eventClient;
        this.hebergementClient = hebergementClient;
        this.transportClient = transportClient;
        this.groq = groq;
        this.maps = maps;
        this.repo = repo;
    }
    public List<Itinerary> myItineraries() {
        String userId = currentUserId();
        if (userId == null || "anonymousUser".equals(userId)) {
            return List.of();
        }
        return repo.findByUserIdOrderByCreatedAtDesc(userId);
    }

    // ✅ NEW: get current logged-in userId (JWT subject)
    private String currentUserId() {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) return null;
        return String.valueOf(auth.getPrincipal());
    }

    public ItineraryResponse generate(ItineraryRequest req) {

        // ===== 1) Fetch candidates from your existing services =====
        List<EventResponse> events = safeEventsByCity(req.toCity());
        events = filterEvents(events, req.interests(), req.maxEventPrice());

        List<HebergementResponse> hebergements = safeHebergements(req.toCity(), req.maxNightPrice());
        HebergementResponse pickedHeb = pickCheapestActive(hebergements);

        String tType = (req.transportType() == null || req.transportType().isBlank())
                ? "TRAIN"
                : req.transportType().trim();

        List<TripResponse> goTrips = safeTrips(req.fromCity(), req.toCity(), req.startDate(), tType);
        List<TripResponse> backTrips = safeTrips(req.toCity(), req.fromCity(), req.endDate(), tType);

        // ===== 2) Ask AI to produce day-by-day narrative JSON =====
        String aiSummary = "";
        Map<LocalDate, String> dayText = new HashMap<>();

        try {
            String system = """
You are an itinerary planner for Morocco travel app RIHLA.
Return ONLY valid JSON (no markdown, no explanation):
{
  "summary": "string",
  "days": [
    { "date": "YYYY-MM-DD", "text": "Morning: ...; Afternoon: ...; Evening: ..." }
  ]
}
Rules:
- Must cover every date from startDate to endDate inclusive.
- Use provided candidates (events, accommodation, trips) when relevant.
""";

            String user = buildAiPrompt(req, events, pickedHeb, goTrips, backTrips);
            String raw = groq.chat(system, user);
            String json = extractJson(raw);

            Map parsed = mapper.readValue(json, Map.class);
            aiSummary = Objects.toString(parsed.get("summary"), "");

            List<Map> days = (List<Map>) parsed.get("days");
            if (days != null) {
                for (Map d : days) {
                    String date = Objects.toString(d.get("date"), null);
                    String text = Objects.toString(d.get("text"), "");
                    if (date != null) dayText.put(LocalDate.parse(date), text);
                }
            }
        } catch (Exception ignored) {
        }

        // ===== 3) Build structured DayPlan with markers + routes =====
        int perDay = (req.limitPerDay() == null || req.limitPerDay() < 1)
                ? 3
                : Math.min(req.limitPerDay(), 8);

        List<EventResponse> pool = new ArrayList<>(events);

        List<DayPlan> out = new ArrayList<>();
        LocalDate d = req.startDate();

        while (!d.isAfter(req.endDate())) {

            List<EventResponse> dayEvents = pickRotate(pool, perDay);

            List<TripResponse> transports = new ArrayList<>();
            if (d.equals(req.startDate())) transports.addAll(goTrips.stream().limit(3).toList());
            if (d.equals(req.endDate())) transports.addAll(backTrips.stream().limit(3).toList());

            // ---- Map pins + trajectory ----
            List<PlaceOnMap> markers = new ArrayList<>();
            List<MapRoute> routes = new ArrayList<>();

            GeoPoint cityPoint = maps.geocode(normalize(req.toCity(), req.toCity()));
            markers.add(new PlaceOnMap("CITY", req.toCity(), req.toCity(), req.toCity() + ", Morocco", cityPoint));

            GeoPoint hebPoint = null;
            if (pickedHeb != null) {
                String hebAddr = normalize(pickedHeb.getAdresse(), pickedHeb.getVille());
                hebPoint = maps.geocode(hebAddr);
                markers.add(new PlaceOnMap("HEBERGEMENT", pickedHeb.getId(), pickedHeb.getNom(), hebAddr, hebPoint));
            }

            GeoPoint last = hebPoint != null ? hebPoint : cityPoint;

            for (EventResponse e : dayEvents) {
                String evAddr = normalize(e.getLieu(), req.toCity());
                GeoPoint evPoint = maps.geocode(evAddr);
                markers.add(new PlaceOnMap("EVENT", e.getId(), e.getNom(), evAddr, evPoint));

                if (last != null && evPoint != null) {
                    MapRoute r = maps.route(last, evPoint);
                    if (r != null) routes.add(r);
                }
                if (evPoint != null) last = evPoint;
            }

            String narrative = dayText.getOrDefault(d, "");
            out.add(new DayPlan(d, pickedHeb, dayEvents, transports, narrative, markers, routes));

            d = d.plusDays(1);
        }

        // ✅ BUILD RESPONSE
        ItineraryResponse res =
                new ItineraryResponse(req.fromCity(), req.toCity(), req.startDate(), req.endDate(), aiSummary, out);

        // ✅ NEW: SAVE TO MONGO (history)
        String userId = currentUserId();
        if (userId != null && !"anonymousUser".equals(userId)) {
            repo.save(new Itinerary(null, userId, LocalDateTime.now(), res));
        }

        return res;
    }

    // ===== helpers =====

    private List<EventResponse> safeEventsByCity(String city) {
        try {
            return eventClient.filterByCity(city);
        } catch (Exception e) {
            try {
                return eventClient.getAll();
            } catch (Exception e2) {
                return List.of();
            }
        }
    }

    private List<HebergementResponse> safeHebergements(String city, Double maxNightPrice) {
        try {
            List<HebergementResponse> list = hebergementClient.search(city, maxNightPrice);
            return list == null ? List.of() : list;
        } catch (Exception e) {
            return List.of();
        }
    }

    private List<TripResponse> safeTrips(String from, String to, LocalDate date, String type) {
        try {
            List<TripResponse> trips = transportClient.search(from, to, date, type);
            return trips == null ? List.of() : trips;
        } catch (Exception e) {
            return List.of();
        }
    }

    private List<EventResponse> filterEvents(List<EventResponse> events, List<String> interests, Double maxPrice) {
        List<EventResponse> res = events == null ? new ArrayList<>() : new ArrayList<>(events);

        if (interests != null && !interests.isEmpty()) {
            Set<String> wanted = interests.stream()
                    .filter(Objects::nonNull)
                    .map(s -> s.toLowerCase(Locale.ROOT).trim())
                    .collect(Collectors.toSet());

            res = res.stream()
                    .filter(e -> e.getCategorie() != null &&
                            wanted.contains(e.getCategorie().toLowerCase(Locale.ROOT).trim()))
                    .toList();
        }

        if (maxPrice != null) {
            res = res.stream()
                    .filter(e -> e.getPrix() != null && e.getPrix() <= maxPrice)
                    .toList();
        }

        return res;
    }

    private HebergementResponse pickCheapestActive(List<HebergementResponse> list) {
        if (list == null || list.isEmpty()) return null;

        List<HebergementResponse> active = list.stream()
                .filter(h -> h.getActif() == null || Boolean.TRUE.equals(h.getActif()))
                .toList();

        if (active.isEmpty()) return null;

        ArrayList<HebergementResponse> sorted = new ArrayList<>(active);
        sorted.sort(Comparator.comparingDouble(h -> h.getPrixParNuit() == null ? Double.MAX_VALUE : h.getPrixParNuit()));
        return sorted.get(0);
    }

    private List<EventResponse> pickRotate(List<EventResponse> pool, int n) {
        if (pool == null || pool.isEmpty()) return List.of();
        List<EventResponse> out = new ArrayList<>();
        for (int i = 0; i < n && !pool.isEmpty(); i++) {
            EventResponse e = pool.remove(0);
            out.add(e);
            pool.add(e);
        }
        return out;
    }

    private String normalize(String placeOrAddr, String city) {
        String a = placeOrAddr == null ? "" : placeOrAddr.trim();
        String c = city == null ? "" : city.trim();
        if (a.isBlank()) return c + ", Morocco";
        if (a.toLowerCase(Locale.ROOT).contains("morocco")) return a;
        if (c.isBlank()) return a + ", Morocco";
        return a + ", " + c + ", Morocco";
    }

    private String buildAiPrompt(ItineraryRequest req,
                                 List<EventResponse> events,
                                 HebergementResponse heb,
                                 List<TripResponse> goTrips,
                                 List<TripResponse> backTrips) throws Exception {

        return """
User request:
fromCity=%s
toCity=%s
startDate=%s
endDate=%s
interests=%s
maxEventPrice=%s
maxNightPrice=%s
transportType=%s

Candidate events:
%s

Selected accommodation:
%s

Go trips:
%s

Return trips:
%s
""".formatted(
                req.fromCity(), req.toCity(), req.startDate(), req.endDate(),
                req.interests(), req.maxEventPrice(), req.maxNightPrice(), req.transportType(),
                mapper.writeValueAsString(events),
                mapper.writeValueAsString(heb),
                mapper.writeValueAsString(goTrips),
                mapper.writeValueAsString(backTrips)
        );
    }

    private String extractJson(String text) {
        if (text == null) return "{}";
        int a = text.indexOf('{');
        int b = text.lastIndexOf('}');
        if (a >= 0 && b > a) return text.substring(a, b + 1);
        return "{}";
    }
}
