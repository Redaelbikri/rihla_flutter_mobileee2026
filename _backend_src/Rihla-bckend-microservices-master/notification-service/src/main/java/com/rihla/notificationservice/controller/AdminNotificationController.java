package com.rihla.notificationservice.controller;

import com.rihla.notificationservice.dto.AdminBroadcastRequest;
import com.rihla.notificationservice.websocket.NotificationPusher;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
@AllArgsConstructor
@RestController
@RequestMapping("/api/notifications/admin")
public class AdminNotificationController {

    private final NotificationPusher pusher;

    @PostMapping("/broadcast")
    @PreAuthorize("hasRole('ADMIN')")
    public void broadcast(@Valid @RequestBody AdminBroadcastRequest req) {
        pusher.pushToAdmins(Map.of(
                "title", req.getTitle(),
                "message", req.getMessage()
        ));
    }
}
