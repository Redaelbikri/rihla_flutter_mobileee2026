package com.rihla.reviewservice.dto;

import com.rihla.reviewservice.entity.ReviewStatus;
import com.rihla.reviewservice.entity.TargetType;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.Set;

@Data
public class ReviewResponseDTO {

    private String id;
    private String userId;

    private String targetId;
    private TargetType targetType;

    private String commentaire;
    private Integer rating;

    private String imageUrl;

    private ReviewStatus status;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    private int likesCount;
    private Set<String> likedUsers;
}
