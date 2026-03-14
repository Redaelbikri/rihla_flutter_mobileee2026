package com.rihla.transportservice.service;

import com.rihla.transportservice.dto.TripRequest;
import com.rihla.transportservice.dto.TripResponse;
import com.rihla.transportservice.entity.TransportType;
import com.rihla.transportservice.entity.Trip;
import com.rihla.transportservice.mapper.TripMapper;
import com.rihla.transportservice.repository.TripRepository;
import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@AllArgsConstructor
@Service
public class TripService {

    private final TripRepository repo;
    private final TripMapper mapper;


    public List<TripResponse> search(String fromCity, String toCity, LocalDate date, TransportType type) {
        LocalDateTime start = date.atStartOfDay();
        LocalDateTime end = date.plusDays(1).atStartOfDay();

        return repo.findByFromCityIgnoreCaseAndToCityIgnoreCaseAndTypeAndDepartureAtBetween(
                fromCity, toCity, type, start, end
        ).stream().map(mapper::toDto).toList();
    }

    public TripResponse getById(String id) {
        Trip t = repo.findById(id).orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Trip not found"));

        return mapper.toDto(t);
    }

    public List<TripResponse> filterByType(TransportType type) {
        return repo.findByType(type).stream().map(mapper::toDto).toList();
    }

    public TripResponse create(TripRequest req) {
        if (req.arrivalAt.isBefore(req.departureAt)) {
            throw new ResponseStatusException(BAD_REQUEST, "arrivalAt must be after departureAt");
        }
        if (req.fromCity.equalsIgnoreCase(req.toCity)) {
            throw new ResponseStatusException(BAD_REQUEST, "fromCity and toCity cannot be same");
        }

        Trip t = mapper.toEntity(req);
        t.setAvailableSeats(t.getCapacity());
        return mapper.toDto(repo.save(t));
    }

    public TripResponse update(String id, TripRequest req) {
        Trip existing = repo.findById(id).orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Trip not found"));

        if (req.arrivalAt.isBefore(req.departureAt)) {
            throw new ResponseStatusException(BAD_REQUEST, "arrivalAt must be after departureAt");
        }
        if (req.fromCity.equalsIgnoreCase(req.toCity)) {
            throw new ResponseStatusException(BAD_REQUEST, "fromCity and toCity cannot be same");
        }


        existing.setFromCity(req.fromCity);
        existing.setToCity(req.toCity);
        existing.setDepartureAt(req.departureAt);
        existing.setArrivalAt(req.arrivalAt);
        existing.setType(req.type);
        existing.setPrice(req.price);
        existing.setCurrency(req.currency);
        existing.setProviderName(req.providerName);


        int booked = existing.getCapacity() - existing.getAvailableSeats();
        if (req.capacity < booked) {
            throw new ResponseStatusException(BAD_REQUEST,
                    "capacity cannot be less than already booked seats: " + booked);
        }
        existing.setCapacity(req.capacity);
        existing.setAvailableSeats(req.capacity - booked);

        return mapper.toDto(repo.save(existing));
    }

    public void delete(String id) {
        if (!repo.existsById(id)) {
            throw new ResponseStatusException(NOT_FOUND, "Trip not found");
        }
        repo.deleteById(id);
    }

    public void reduceSeats(String tripId, int quantity) {

        if (quantity <= 0)
            throw new ResponseStatusException(BAD_REQUEST, "quantity must be > 0");

        Trip t = repo.findById(tripId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Trip not found"));

        if (t.getAvailableSeats() < quantity)
            throw new ResponseStatusException(BAD_REQUEST, "Not enough seats available");

        t.setAvailableSeats(t.getAvailableSeats() - quantity);
        repo.save(t);
    }

    public boolean checkAvailability(String tripId, int quantity) {
        if (quantity <= 0) return false;
        Trip t = repo.findById(tripId).orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Trip not found"));
        return t.getAvailableSeats() >= quantity;
    }
}
