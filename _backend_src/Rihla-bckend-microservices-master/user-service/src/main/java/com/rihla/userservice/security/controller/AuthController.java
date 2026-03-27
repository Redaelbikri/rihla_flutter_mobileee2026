package com.rihla.userservice.security.controller;

import com.rihla.userservice.entity.User;
import com.rihla.userservice.googleAuth.Provider;
import com.rihla.userservice.googleAuth.dto.GoogleAuthRequest;
import com.rihla.userservice.googleAuth.google.GoogleAuthService;
import com.rihla.userservice.otp.EmailService;
import com.rihla.userservice.otp.OtpService;
import com.rihla.userservice.otp.OtpType;
import com.rihla.userservice.otp.dto.ForgotPasswordRequest;
import com.rihla.userservice.otp.dto.ResetPasswordRequest;
import com.rihla.userservice.otp.dto.VerifyEmailRequest;
import com.rihla.userservice.otp.dto.VerifyLoginRequest;
import com.rihla.userservice.repository.UserRepository;
import com.rihla.userservice.security.jwt.JwtUtils;
import com.rihla.userservice.security.payload.JwtResponse;
import com.rihla.userservice.security.payload.LoginRequest;
import com.rihla.userservice.security.payload.SignupRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final GoogleAuthService googleAuthService;
    private final UserRepository userRepository;
    private final PasswordEncoder encoder;
    private final JwtUtils jwtUtils;
    private final OtpService otpService;
    private final EmailService emailService;

    public AuthController(
            GoogleAuthService googleAuthService,
            UserRepository userRepository,
            PasswordEncoder encoder,
            JwtUtils jwtUtils,
            OtpService otpService,
            EmailService emailService
    ) {
        this.googleAuthService = googleAuthService;
        this.userRepository = userRepository;
        this.encoder = encoder;
        this.jwtUtils = jwtUtils;
        this.otpService = otpService;
        this.emailService = emailService;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Flow 1 — Signup + Email Verification
    // ──────────────────────────────────────────────────────────────────────────

    @PostMapping({"/signup", "/register"})
    public ResponseEntity<?> signup(@Valid @RequestBody SignupRequest req) {
        if (userRepository.findByEmail(req.getEmail()).isPresent()) {
            return ResponseEntity.badRequest().body("Error: Email already in use!");
        }

        User user = new User();
        user.setNom(req.getNom());
        user.setPrenom(req.getPrenom());
        user.setEmail(req.getEmail());
        user.setTelephone(req.getTelephone());
        user.setMotDePasse(encoder.encode(req.getPassword()));
        user.setRoles(List.of("ROLE_USER"));
        user.setProvider(Provider.LOCAL);
        user.setEnabled(false); // enabled after email verification

        userRepository.save(user);

        String code = otpService.generateAndSave(req.getEmail(), OtpType.EMAIL_VERIFICATION);
        emailService.sendOtp(req.getEmail(), OtpType.EMAIL_VERIFICATION, code);

        return ResponseEntity.ok(Map.of(
                "message", "Account created. Please verify your email with the OTP sent to " + req.getEmail()
        ));
    }

    @PostMapping("/verify-email")
    public ResponseEntity<?> verifyEmail(@Valid @RequestBody VerifyEmailRequest req) {
        if (!otpService.validate(req.getEmail(), OtpType.EMAIL_VERIFICATION, req.getCode())) {
            return ResponseEntity.badRequest().body("Invalid or expired OTP.");
        }

        User user = userRepository.findByEmail(req.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setEnabled(true);
        userRepository.save(user);

        String jwt = jwtUtils.generateTokenFromEmailAndRoles(user.getEmail(), user.getRoles());
        return ResponseEntity.ok(new JwtResponse(jwt, user.getId(), user.getEmail(), user.getRoles()));
    }

    @PostMapping("/resend-otp")
    public ResponseEntity<?> resendOtp(@RequestBody Map<String, String> body) {
        String email = body.get("email");
        String flow = body.getOrDefault("flow", "signup");
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest().body("Email is required.");
        }

        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) {
            // Return generic message to avoid user enumeration
            return ResponseEntity.ok(Map.of("message", "If that email exists, an OTP was sent."));
        }

        if ("login".equalsIgnoreCase(flow)) {
            if (!user.isEnabled()) {
                return ResponseEntity.badRequest().body("Email not verified. Please check your inbox.");
            }
            if (user.getProvider() != Provider.LOCAL) {
                return ResponseEntity.badRequest().body("Please sign in with Google.");
            }
            String code = otpService.generateAndSave(email, OtpType.LOGIN_2FA);
            emailService.sendOtp(email, OtpType.LOGIN_2FA, code);
            return ResponseEntity.ok(Map.of("message", "Login OTP resent to " + email));
        }

        if (user.isEnabled()) {
            return ResponseEntity.badRequest().body("Email already verified.");
        }
        String code = otpService.generateAndSave(email, OtpType.EMAIL_VERIFICATION);
        emailService.sendOtp(email, OtpType.EMAIL_VERIFICATION, code);
        return ResponseEntity.ok(Map.of("message", "OTP resent to " + email));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Flow 2 — Login with 2FA (LOCAL users only)
    // ──────────────────────────────────────────────────────────────────────────

    @PostMapping({"/signin", "/login"})
    public ResponseEntity<?> signin(@Valid @RequestBody LoginRequest req) {
        User user = userRepository.findByEmail(req.getEmail()).orElse(null);

        if (user == null || !encoder.matches(req.getPassword(), user.getMotDePasse())) {
            return ResponseEntity.badRequest().body("Invalid email or password.");
        }

        if (!user.isEnabled()) {
            return ResponseEntity.badRequest().body("Email not verified. Please check your inbox.");
        }

        // Google accounts should use /api/auth/google
        if (user.getProvider() != Provider.LOCAL) {
            return ResponseEntity.badRequest().body("Please sign in with Google.");
        }

        String code = otpService.generateAndSave(req.getEmail(), OtpType.LOGIN_2FA);
        emailService.sendOtp(req.getEmail(), OtpType.LOGIN_2FA, code);

        return ResponseEntity.ok(Map.of(
                "requiresOtp", true,
                "email", req.getEmail(),
                "message", "OTP sent to your email"
        ));
    }

    @PostMapping("/verify-login")
    public ResponseEntity<?> verifyLogin(@Valid @RequestBody VerifyLoginRequest req) {
        if (!otpService.validate(req.getEmail(), OtpType.LOGIN_2FA, req.getCode())) {
            return ResponseEntity.badRequest().body("Invalid or expired OTP.");
        }

        User user = userRepository.findByEmail(req.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        String jwt = jwtUtils.generateTokenFromEmailAndRoles(user.getEmail(), user.getRoles());
        return ResponseEntity.ok(new JwtResponse(jwt, user.getId(), user.getEmail(), user.getRoles()));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Flow 3 — Password Reset
    // ──────────────────────────────────────────────────────────────────────────

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@Valid @RequestBody ForgotPasswordRequest req) {
        User user = userRepository.findByEmail(req.getEmail()).orElse(null);
        if (user != null && user.getProvider() == Provider.LOCAL) {
            String code = otpService.generateAndSave(req.getEmail(), OtpType.PASSWORD_RESET);
            emailService.sendOtp(req.getEmail(), OtpType.PASSWORD_RESET, code);
        }
        // Always return the same response to avoid user enumeration
        return ResponseEntity.ok(Map.of("message", "If that email exists, an OTP was sent."));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@Valid @RequestBody ResetPasswordRequest req) {
        if (!otpService.validate(req.getEmail(), OtpType.PASSWORD_RESET, req.getCode())) {
            return ResponseEntity.badRequest().body("Invalid or expired OTP.");
        }

        User user = userRepository.findByEmail(req.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setMotDePasse(encoder.encode(req.getNewPassword()));
        userRepository.save(user);

        return ResponseEntity.ok(Map.of("message", "Password updated successfully."));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Google OAuth (no OTP step)
    // ──────────────────────────────────────────────────────────────────────────

    @PostMapping("/google")
    public ResponseEntity<?> googleAuth(@Valid @RequestBody GoogleAuthRequest req) {
        User user = googleAuthService.loginOrRegister(req.getIdToken());

        String jwt = jwtUtils.generateTokenFromEmailAndRoles(user.getEmail(), user.getRoles());

        Map<String, Object> resp = new HashMap<>();
        resp.put("accessToken", jwt);
        resp.put("tokenType", "Bearer");
        resp.put("userId", user.getId());
        resp.put("email", user.getEmail());
        resp.put("roles", user.getRoles());
        resp.put("provider", user.getProvider() != null ? user.getProvider().name() : "GOOGLE");
        resp.put("enabled", user.isEnabled());

        return ResponseEntity.ok(resp);
    }
}
