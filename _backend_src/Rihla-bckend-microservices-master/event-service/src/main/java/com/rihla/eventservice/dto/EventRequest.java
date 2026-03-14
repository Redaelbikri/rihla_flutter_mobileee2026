package com.rihla.eventservice.dto;
import lombok.Data;

@Data
public class EventRequest {
    private String nom;
    private String description;
    private String lieu;
    private String categorie;
    private String dateEvent;
    private Double prix;
    private Integer placesDisponibles;
    private String imageUrl;
}