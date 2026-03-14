package com.rihla.reservationservice.DTO;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;

public class CreateReservationItem {
    @NotBlank public String id;
    @Min(1) public int quantity;
}
