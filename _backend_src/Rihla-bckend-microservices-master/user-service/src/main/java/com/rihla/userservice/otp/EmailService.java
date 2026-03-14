package com.rihla.userservice.otp;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendOtp(String to, OtpType type, String code) {
        String subject = switch (type) {
            case EMAIL_VERIFICATION -> "[Rihla] Vérifiez votre adresse e-mail";
            case LOGIN_2FA          -> "[Rihla] Code de connexion";
            case PASSWORD_RESET     -> "[Rihla] Réinitialisation de mot de passe";
        };

        String action = switch (type) {
            case EMAIL_VERIFICATION -> "vérifier votre adresse e-mail";
            case LOGIN_2FA          -> "finaliser votre connexion";
            case PASSWORD_RESET     -> "réinitialiser votre mot de passe";
        };

        String html = """
                <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto">
                  <h2 style="color:#2c3e50">Rihla — Votre code OTP</h2>
                  <p>Utilisez le code ci-dessous pour %s :</p>
                  <div style="font-size:36px;font-weight:bold;letter-spacing:8px;
                              color:#2980b9;padding:16px;background:#f0f4f8;
                              border-radius:8px;text-align:center">%s</div>
                  <p style="color:#7f8c8d;margin-top:16px">
                    Ce code est valable <strong>10 minutes</strong>.<br>
                    Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.
                  </p>
                </div>
                """.formatted(action, code);

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, "UTF-8");
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(html, true);
            mailSender.send(message);
        } catch (MessagingException e) {
            throw new RuntimeException("Failed to send OTP email to " + to, e);
        }
    }
}
