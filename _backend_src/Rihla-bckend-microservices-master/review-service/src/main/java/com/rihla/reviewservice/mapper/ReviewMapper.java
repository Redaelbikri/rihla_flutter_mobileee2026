package com.rihla.reviewservice.mapper;

import com.rihla.reviewservice.dto.ReviewRequestDTO;
import com.rihla.reviewservice.dto.ReviewResponseDTO;
import com.rihla.reviewservice.entity.Review;
import org.springframework.stereotype.Component;

@Component
public class ReviewMapper {

    public Review toEntity(ReviewRequestDTO dto, String userId) {
        Review r = new Review();
        r.setUserId(userId);
        r.setTargetId(dto.getTargetId());
        r.setTargetType(dto.getTargetType());
        r.setCommentaire(dto.getCommentaire());
        r.setRating(dto.getRating());
        return r;
    }

    public ReviewResponseDTO toDTO(Review r) {
        ReviewResponseDTO dto = new ReviewResponseDTO();
        dto.setId(r.getId());
        dto.setUserId(r.getUserId());

        dto.setTargetId(r.getTargetId());
        dto.setTargetType(r.getTargetType());

        dto.setCommentaire(r.getCommentaire());
        dto.setRating(r.getRating());
        dto.setImageUrl(r.getImageUrl());

        dto.setStatus(r.getStatus());
        dto.setCreatedAt(r.getCreatedAt());
        dto.setUpdatedAt(r.getUpdatedAt());

        dto.setLikedUsers(r.getLikedUsers());
        dto.setLikesCount(r.getLikedUsers() == null ? 0 : r.getLikedUsers().size());
        return dto;
    }
}
