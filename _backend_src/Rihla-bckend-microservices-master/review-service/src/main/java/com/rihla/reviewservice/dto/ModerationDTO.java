package com.rihla.reviewservice.dto;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ModerationDTO {

    @Size(max = 300)
    private String note;
}
