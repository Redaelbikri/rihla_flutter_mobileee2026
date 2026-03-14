package com.rihla.userservice.otp.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class VerifyLoginRequest {
    @NotBlank @Email
    private String email;
    @NotBlank
    private String code;
}
