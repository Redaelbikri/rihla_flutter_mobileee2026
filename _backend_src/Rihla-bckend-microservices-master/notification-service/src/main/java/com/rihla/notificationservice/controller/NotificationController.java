package com.rihla.notificationservice.controller;

import com.rihla.notificationservice.entity.Notification;
import com.rihla.notificationservice.repository.NotificationRepository;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
@AllArgsConstructor
@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationRepository repo;


    @GetMapping("/me")
    public List<Notification> myNotifications(Authentication auth) {
        String userSubject = auth.getName();
        return repo.findByUserSubjectOrderByCreatedAtDesc(userSubject);
    }

    @GetMapping("/me/unread-count")
    public Map<String, Long> unread(Authentication auth) {
        String userSubject = auth.getName();
        return Map.of("unread", repo.countByUserSubjectAndReadFalse(userSubject));
    }

    @PutMapping("/{id}/read")
    public void markRead(@PathVariable String id, Authentication auth) {
        String userSubject = auth.getName();
        Notification n = repo.findByIdAndUserSubject(id, userSubject)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Notification not found"));
        n.setRead(true);
        repo.save(n);
    }
}
