package com.rihla.reviewservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class RatingStatsDTO {
    private long count;
    private double average;
}
