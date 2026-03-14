package com.rihla.userservice.dto;

import lombok.Data;
import java.util.List;

@Data
public class UserResponse {
    private String id;
    private String nom;
    private String prenom;
    private String email;
    private String telephone;
    private List<String> roles;

}