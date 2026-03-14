package com.rihla.reviewservice.dto;

import com.rihla.reviewservice.entity.TargetType;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ReviewRequestDTO {

    @NotBlank
    private String targetId;

    @NotNull
    private TargetType targetType;

    @Size(max = 500)
    private String commentaire;

    @NotNull
    @Min(1) @Max(5)
    private Integer rating;
}
