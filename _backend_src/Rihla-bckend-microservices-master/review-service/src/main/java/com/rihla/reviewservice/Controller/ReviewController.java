package com.rihla.reviewservice.Controller;

import com.rihla.reviewservice.dto.*;
import com.rihla.reviewservice.entity.TargetType;
import com.rihla.reviewservice.service.ReviewService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.security.Principal;

@RestController
@RequestMapping("/api/reviews")
public class ReviewController {

    @Autowired
    private ReviewService service;

    // ✅ USER create (goes to PENDING)
    @PostMapping
    public ReviewResponseDTO create(
            @Valid @RequestPart ReviewRequestDTO dto,
            @RequestPart(required = false) MultipartFile image,
            Principal principal
    ) {
        return service.create(dto, image, principal.getName());
    }

    // ✅ Public: GET approved reviews by target + pagination
    @GetMapping("/{type}/{id}")
    public Page<ReviewResponseDTO> getApproved(
            @PathVariable TargetType type,
            @PathVariable String id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return service.getApprovedReviews(id, type, page, size);
    }

    // ✅ Public: stats
    @GetMapping("/{type}/{id}/stats")
    public RatingStatsDTO stats(
            @PathVariable TargetType type,
            @PathVariable String id
    ) {
        return service.stats(id, type);
    }

    // ✅ USER: my reviews
    @GetMapping("/me")
    public Page<ReviewResponseDTO> myReviews(
            Principal principal,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return service.myReviews(principal.getName(), page, size);
    }

    // ✅ USER: update my review => back to PENDING
    @PutMapping("/{id}")
    public ReviewResponseDTO update(
            @PathVariable String id,
            @Valid @RequestBody ReviewUpdateDTO dto,
            Principal principal
    ) {
        return service.update(id, dto, principal.getName());
    }

    // ✅ like
    @PutMapping("/{id}/like")
    public ReviewResponseDTO like(
            @PathVariable String id,
            Principal principal
    ) {
        return service.like(id, principal.getName());
    }

    // ✅ USER delete (soft)
    @DeleteMapping("/{id}")
    public void deleteMy(
            @PathVariable String id,
            Principal principal
    ) {
        service.deleteMyReview(id, principal.getName());
    }

    // ✅ ADMIN can also delete via same endpoint (role already checked in security if you want)
    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/admin/{id}/hard")
    public void deleteHard(@PathVariable String id) {
        // hard delete only for admin (optional)
        // if you want it, add repo.deleteById in service
        throw new UnsupportedOperationException("NOT IMPLEMENTED (optional). Use soft delete.");
    }
}
