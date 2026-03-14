package com.rihla.notificationservice.entity;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

@Data
@Document("notifications")
public class Notification {

    @Id
    private String id;

    @Indexed
    private String userSubject;

    @Indexed
    private String type;

    private String title;
    private String message;

    @Indexed
    private boolean read;

    @Indexed
    private Instant createdAt;


    @Indexed(unique = true, sparse = true)
    private String sourceKey;

    @Indexed(sparse = true)
    private String sourceEventId;
}
