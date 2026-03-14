package com.rihla.userservice.dto;

import lombok.Data;
import java.util.List;

@Data
public class UserRequest {
    private String nom;
    private String prenom;
    private String email;
    private String motDePasse;
    private String telephone;
    private List<String> roles;
}