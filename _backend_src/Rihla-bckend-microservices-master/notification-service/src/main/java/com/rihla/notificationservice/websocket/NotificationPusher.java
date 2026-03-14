package com.rihla.notificationservice.websocket;

import lombok.AllArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
@AllArgsConstructor
@Service
public class NotificationPusher {

    private final SimpMessagingTemplate template;


    public void pushToUser(String userSubject, Object payload) {
        template.convertAndSendToUser(userSubject, "/queue/notifications", payload);
    }

    public void pushToAdmins(Object payload) {
        template.convertAndSend("/topic/admin-notifications", payload);
    }
}
