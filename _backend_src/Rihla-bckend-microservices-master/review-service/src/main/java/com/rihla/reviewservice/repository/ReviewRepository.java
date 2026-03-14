package com.rihla.reviewservice.repository;

import com.rihla.reviewservice.entity.Review;
import com.rihla.reviewservice.entity.ReviewStatus;
import com.rihla.reviewservice.entity.TargetType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface ReviewRepository extends MongoRepository<Review, String> {

    Page<Review> findByTargetIdAndTargetTypeAndStatus(String targetId, TargetType targetType, ReviewStatus status, Pageable pageable);

    Optional<Review> findByUserIdAndTargetIdAndTargetType(String userId, String targetId, TargetType targetType);

    Page<Review> findByUserIdAndStatusNot(String userId, ReviewStatus status, Pageable pageable);

    Page<Review> findByStatus(ReviewStatus status, Pageable pageable);

    long countByTargetIdAndTargetTypeAndStatus(String targetId, TargetType targetType, ReviewStatus status);
}
