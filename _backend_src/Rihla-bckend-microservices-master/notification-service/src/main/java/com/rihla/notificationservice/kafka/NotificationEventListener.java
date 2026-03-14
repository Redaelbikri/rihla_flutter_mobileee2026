package com.rihla.notificationservice.kafka;

import com.rihla.notificationservice.entity.Notification;
import com.rihla.notificationservice.repository.NotificationRepository;
import com.rihla.notificationservice.websocket.NotificationPusher;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
public class NotificationEventListener {

    private final NotificationRepository repo;
    private final NotificationPusher pusher;

    public NotificationEventListener(NotificationRepository repo, NotificationPusher pusher) {
        this.repo = repo;
        this.pusher = pusher;
    }

    @KafkaListener(topics = {"reservation.events", "payment.events"}, groupId = "notification-service")
    public void onEvent(DomainEvent event) {
        if (event == null) return;
        if (event.userSubject() == null || event.userSubject().isBlank()) return;

        String eventId = (event.eventId() == null ? "" : event.eventId().trim());
        String eventType = (event.eventType() == null ? "" : event.eventType().trim());



        String sourceKey = (!eventType.isBlank() && !eventId.isBlank())
                ? (eventType + ":" + eventId)
                : null;

        if (sourceKey != null && repo.existsBySourceKey(sourceKey)) {
            return;
        }

        Notification n = new Notification();
        n.setUserSubject(event.userSubject());
        n.setType(eventType.isBlank() ? "UNKNOWN" : eventType);
        n.setTitle(event.title() == null ? n.getType() : event.title());
        n.setMessage(event.message() == null ? "" : event.message());
        n.setRead(false);
        n.setCreatedAt(Instant.now());

        n.setSourceKey(sourceKey);
        n.setSourceEventId(eventId.isBlank() ? null : eventId);

        repo.save(n);
        pusher.pushToUser(event.userSubject(), n);
    }
}
