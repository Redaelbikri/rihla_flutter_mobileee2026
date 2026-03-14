package com.rihla.userservice.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.rihla.userservice.googleAuth.Provider;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Document(collection = "users")
public class User {
    @Id
    private String id;

    @NotBlank(message = "Le nom est obligatoire")
    private String nom;

    @NotBlank(message = "Le prénom est obligatoire")
    private String prenom;

    @NotBlank
    @Email(message = "Format email invalide")
    @Indexed(unique = true)
    private String email;

    @NotBlank
    @Size(min = 6, message = "Le mot de passe doit contenir au moins 6 caractères")
    @JsonIgnore
    private String motDePasse;

    private String telephone;

    private List<String> roles;

    private LocalDateTime dateCreation;
    private String statut;

    public User() {
        this.dateCreation = LocalDateTime.now();
        this.statut = "ACTIF";
    }
    private Provider provider = Provider.LOCAL;
    private String googleSub;       // unique Google user id
    private boolean enabled = true; // LOCAL can be false until email verify; GOOGLE = true
}