package com.rihla.recommendationservice.dto;

import lombok.Data;

@Data
public class HebergementResponse {
    private String id;
    private String nom;
    private String ville;
    private String adresse;
    private String type;
    private Double prixParNuit;
    private Integer chambresDisponibles;
    private Double note;
    private String imageUrl;
    private Boolean actif;
}
