package com.rihla.eventservice.dto;
import lombok.Data;
import java.time.LocalDateTime;

@Data
public class EventResponse {
    private String id;
    private String nom;
    private String description;
    private String lieu;
    private String categorie;
    private LocalDateTime dateEvent;
    private Double prix;
    private Integer placesDisponibles;
    private String imageUrl;
}