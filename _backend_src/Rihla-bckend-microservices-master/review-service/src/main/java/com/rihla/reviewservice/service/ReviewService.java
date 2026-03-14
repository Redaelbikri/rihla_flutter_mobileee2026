package com.rihla.reviewservice.service;

import com.rihla.reviewservice.dto.*;
import com.rihla.reviewservice.entity.Review;
import com.rihla.reviewservice.entity.ReviewStatus;
import com.rihla.reviewservice.entity.TargetType;
import com.rihla.reviewservice.mapper.ReviewMapper;
import com.rihla.reviewservice.repository.ReviewRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.time.LocalDateTime;

@Service
public class ReviewService {

    @Autowired private ReviewRepository repo;
    @Autowired private ReviewMapper mapper;

    private final String uploadDir = "uploads/";

    public ReviewResponseDTO create(ReviewRequestDTO dto, MultipartFile image, String userId) {
        Review review = mapper.toEntity(dto, userId);
        review.setStatus(ReviewStatus.PENDING);
        review.setCreatedAt(LocalDateTime.now());
        review.setUpdatedAt(LocalDateTime.now());

        // ✅ Image upload optional (comme ton code)
        if (image != null && !image.isEmpty()) {
            try {
                File dir = new File(uploadDir);
                if (!dir.exists()) dir.mkdirs();

                String safeName = System.currentTimeMillis() + "_" + image.getOriginalFilename();
                String path = uploadDir + safeName;
                image.transferTo(new File(path));
                review.setImageUrl(path);
            } catch (Exception e) {
                throw new IllegalStateException("Image upload failed");
            }
        }

        try {
            return mapper.toDTO(repo.save(review));
        } catch (DuplicateKeyException e) {
            // ✅ anti-doublon: 1 review par user/cible
            throw new IllegalStateException("You already reviewed this target.");
        }
    }

    // ✅ Public: list APPROVED reviews by target (pagination)
    public Page<ReviewResponseDTO> getApprovedReviews(String targetId, TargetType type, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        return repo.findByTargetIdAndTargetTypeAndStatus(targetId, type, ReviewStatus.APPROVED, pageable)
                .map(mapper::toDTO);
    }

    // ✅ USER: my reviews
    public Page<ReviewResponseDTO> myReviews(String userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        return repo.findByUserIdAndStatusNot(userId, ReviewStatus.DELETED, pageable)
                .map(mapper::toDTO);
    }

    // ✅ USER: update my review => back to PENDING
    public ReviewResponseDTO update(String reviewId, ReviewUpdateDTO dto, String userId) {
        Review r = repo.findById(reviewId).orElseThrow(() -> new IllegalArgumentException("Review not found"));
        if (!r.getUserId().equals(userId)) throw new SecurityException("Not your review");
        if (r.getStatus() == ReviewStatus.DELETED) throw new IllegalStateException("Review deleted");

        if (dto.getRating() != null) r.setRating(dto.getRating());
        if (dto.getCommentaire() != null) r.setCommentaire(dto.getCommentaire());

        r.setStatus(ReviewStatus.PENDING);
        r.setUpdatedAt(LocalDateTime.now());
        return mapper.toDTO(repo.save(r));
    }

    // ✅ like
    public ReviewResponseDTO like(String reviewId, String userId) {
        Review review = repo.findById(reviewId).orElseThrow(() -> new IllegalArgumentException("Review not found"));
        if (review.getStatus() == ReviewStatus.DELETED) throw new IllegalStateException("Review deleted");
        review.getLikedUsers().add(userId);
        review.setUpdatedAt(LocalDateTime.now());
        return mapper.toDTO(repo.save(review));
    }

    // ✅ USER delete (soft)
    public void deleteMyReview(String reviewId, String userId) {
        Review r = repo.findById(reviewId).orElseThrow(() -> new IllegalArgumentException("Review not found"));
        if (!r.getUserId().equals(userId)) throw new SecurityException("Not your review");
        r.setStatus(ReviewStatus.DELETED);
        r.setUpdatedAt(LocalDateTime.now());
        repo.save(r);
    }

    // ✅ ADMIN: pending list
    public Page<ReviewResponseDTO> pending(int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.ASC, "createdAt"));
        return repo.findByStatus(ReviewStatus.PENDING, pageable).map(mapper::toDTO);
    }

    // ✅ ADMIN approve/reject
    public ReviewResponseDTO approve(String reviewId, String adminId, ModerationDTO dto) {
        Review r = repo.findById(reviewId).orElseThrow(() -> new IllegalArgumentException("Review not found"));
        r.setStatus(ReviewStatus.APPROVED);
        r.setModeratedBy(adminId);
        r.setModerationNote(dto == null ? null : dto.getNote());
        r.setUpdatedAt(LocalDateTime.now());
        return mapper.toDTO(repo.save(r));
    }

    public ReviewResponseDTO reject(String reviewId, String adminId, ModerationDTO dto) {
        Review r = repo.findById(reviewId).orElseThrow(() -> new IllegalArgumentException("Review not found"));
        r.setStatus(ReviewStatus.REJECTED);
        r.setModeratedBy(adminId);
        r.setModerationNote(dto == null ? null : dto.getNote());
        r.setUpdatedAt(LocalDateTime.now());
        return mapper.toDTO(repo.save(r));
    }

    // ✅ Stats (APPROVED only)
    public RatingStatsDTO stats(String targetId, TargetType type) {
        var list = repo.findByTargetIdAndTargetTypeAndStatus(targetId, type, ReviewStatus.APPROVED, Pageable.unpaged())
                .getContent();
        long count = list.size();
        double avg = count == 0 ? 0.0 : list.stream().mapToInt(Review::getRating).average().orElse(0.0);
        return new RatingStatsDTO(count, avg);
    }
}
