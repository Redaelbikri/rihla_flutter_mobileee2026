package com.rihla.eventservice.service;

import com.rihla.eventservice.dto.EventRequest;
import com.rihla.eventservice.dto.EventResponse;
import com.rihla.eventservice.entity.Event;
import com.rihla.eventservice.mapper.EventMapper;
import com.rihla.eventservice.repository.EventRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class EventService {

    @Autowired
    private EventRepository repository;
    @Autowired
    private EventMapper mapper;


    public EventResponse createEvent(EventRequest request) {
        Event event = mapper.toEntity(request);
        if (request.getDateEvent() != null) {
            event.setDateEvent(LocalDateTime.parse(request.getDateEvent()));
        }
        return mapper.toDto(repository.save(event));
    }


    public List<EventResponse> getAllEvents() {
        return repository.findAll().stream()
                .map(mapper::toDto)
                .collect(Collectors.toList());
    }

    public EventResponse getEventById(String id) {
        return repository.findById(id)
                .map(mapper::toDto)
                .orElseThrow(() -> new RuntimeException("Event not found with ID: " + id));
    }

    public List<EventResponse> searchEvents(String keyword) {
        return repository.findByNomContainingIgnoreCase(keyword).stream()
                .map(mapper::toDto)
                .collect(Collectors.toList());
    }

    public List<EventResponse> filterByCategory(String category) {
        return repository.findByCategorie(category).stream()
                .map(mapper::toDto)
                .collect(Collectors.toList());
    }

    public List<EventResponse> filterByCity(String city) {
        return repository.findByLieuContainingIgnoreCase(city).stream()
                .map(mapper::toDto)
                .collect(Collectors.toList());
    }


    public EventResponse updateEvent(String id, EventRequest request) {
        Event event = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Event not found"));

        event.setNom(request.getNom());
        event.setDescription(request.getDescription());
        event.setLieu(request.getLieu());
        event.setCategorie(request.getCategorie());
        event.setPrix(request.getPrix());
        event.setImageUrl(request.getImageUrl());


        if(request.getPlacesDisponibles() != null) {
            event.setPlacesDisponibles(request.getPlacesDisponibles());
        }

        if (request.getDateEvent() != null) {
            event.setDateEvent(LocalDateTime.parse(request.getDateEvent()));
        }

        return mapper.toDto(repository.save(event));
    }


    public void deleteEvent(String id) {
        if (!repository.existsById(id)) {
            throw new RuntimeException("Event not found");
        }
        repository.deleteById(id);
    }


    @Transactional
    public void decreaseStock(String id, int quantity) {
        Event event = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Event not found"));

        if (event.getPlacesDisponibles() < quantity) {
            throw new RuntimeException("SOLD OUT: Not enough places available.");
        }

        event.setPlacesDisponibles(event.getPlacesDisponibles() - quantity);
        repository.save(event);
    }

    public boolean checkAvailability(String id, int quantity) {
        Event event = repository.findById(id).orElseThrow();
        return event.getPlacesDisponibles() >= quantity;
    }
}