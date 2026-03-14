package com.rihla.reviewservice.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ReviewUpdateDTO {

    @Min(1) @Max(5)
    private Integer rating;

    @Size(max = 500)
    private String commentaire;
}
