package com.rihla.notificationservice.repository;

import com.rihla.notificationservice.entity.Notification;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;
import java.util.Optional;

public interface NotificationRepository extends MongoRepository<Notification, String> {

    List<Notification> findByUserSubjectOrderByCreatedAtDesc(String userSubject);

    long countByUserSubjectAndReadFalse(String userSubject);

    Optional<Notification> findByIdAndUserSubject(String id, String userSubject);

    boolean existsBySourceKey(String sourceKey);
}
