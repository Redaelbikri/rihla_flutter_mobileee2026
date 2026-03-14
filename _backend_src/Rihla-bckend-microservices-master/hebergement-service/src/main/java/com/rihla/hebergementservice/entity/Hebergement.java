package com.rihla.hebergementservice.entity;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Document(collection = "hebergements")
public class Hebergement {
    @Id
    private String id;

    private String nom;
    private String ville;
    private String adresse;

    private HebergementType type;

    private Double prixParNuit;
    private Integer chambresDisponibles;

    private Double note;
    private String imageUrl;

    private Boolean actif = true;
}
