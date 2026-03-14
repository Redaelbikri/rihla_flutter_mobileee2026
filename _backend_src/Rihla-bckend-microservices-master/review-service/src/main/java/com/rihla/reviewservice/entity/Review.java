package com.rihla.reviewservice.entity;

import lombok.Data;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Data
@Document("reviews")
@CompoundIndex(
        name = "uniq_user_target",
        def = "{'userId': 1, 'targetId': 1, 'targetType': 1}",
        unique = true
)
public class Review {

    @Id
    private String id;

    @Indexed
    private String userId; // principal.getName() = email chez toi

    @Indexed
    private String targetId;

    @Indexed
    private TargetType targetType;

    private String commentaire;
    private Integer rating; // 1..5

    private String imageUrl;

    @Indexed
    private ReviewStatus status = ReviewStatus.PENDING; // ✅ modération

    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime updatedAt = LocalDateTime.now();

    private String moderatedBy;      // admin email
    private String moderationNote;   // note admin

    private Set<String> likedUsers = new HashSet<>();
}
