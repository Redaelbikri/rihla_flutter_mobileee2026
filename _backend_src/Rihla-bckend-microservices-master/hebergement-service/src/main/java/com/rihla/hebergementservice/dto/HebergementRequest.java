package com.rihla.hebergementservice.dto;

import com.rihla.hebergementservice.entity.HebergementType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class HebergementRequest {

    @NotBlank private String nom;
    @NotBlank private String ville;
    @NotBlank private String adresse;

    @NotNull private HebergementType type;

    @NotNull @Min(0)
    private Double prixParNuit;

    @NotNull @Min(0)
    private Integer chambresDisponibles;

    private Double note;
    private String imageUrl;
}
