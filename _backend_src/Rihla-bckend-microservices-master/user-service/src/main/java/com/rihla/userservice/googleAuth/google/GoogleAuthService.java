package com.rihla.userservice.googleAuth.google;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.rihla.userservice.entity.User;
import com.rihla.userservice.googleAuth.Provider;
import com.rihla.userservice.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class GoogleAuthService {

    private final GoogleIdTokenVerifierService googleVerifier;
    private final UserRepository userRepository;

    public GoogleAuthService(GoogleIdTokenVerifierService googleVerifier,
                             UserRepository userRepository) {
        this.googleVerifier = googleVerifier;
        this.userRepository = userRepository;
    }

    public User loginOrRegister(String idToken) {

        GoogleIdToken.Payload payload = googleVerifier.verify(idToken);

        if (!Boolean.TRUE.equals(payload.getEmailVerified())) {
            throw new IllegalArgumentException("Google account email is not verified");
        }

        String email = payload.getEmail();
        String sub = payload.getSubject();
        String givenName  = (String) payload.get("given_name");
        String familyName = (String) payload.get("family_name");

        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("Google token has no email");
        }

        User u = userRepository.findByGoogleSub(sub).orElse(null);
        if (u != null) return u;

        u = userRepository.findByEmail(email).orElse(null);
        if (u != null) {
            u.setProvider(Provider.GOOGLE);
            u.setGoogleSub(sub);
            u.setEnabled(true);
            return userRepository.save(u);
        }

        User newUser = new User();
        newUser.setEmail(email);
        newUser.setNom(familyName != null ? familyName : "");
        newUser.setPrenom(givenName != null ? givenName : "");
        newUser.setProvider(Provider.GOOGLE);
        newUser.setGoogleSub(sub);
        newUser.setEnabled(true);
        newUser.setRoles(java.util.List.of("ROLE_USER"));

        return userRepository.save(newUser);
    }
}