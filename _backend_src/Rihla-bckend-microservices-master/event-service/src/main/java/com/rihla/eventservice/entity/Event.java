package com.rihla.eventservice.entity;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.time.LocalDateTime;

@Data
@Document(collection = "events")
public class Event {
    @Id
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