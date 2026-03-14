package com.rihla.reviewservice.Controller;

import com.rihla.reviewservice.dto.ModerationDTO;
import com.rihla.reviewservice.dto.ReviewResponseDTO;
import com.rihla.reviewservice.service.ReviewService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;

@RestController
@RequestMapping("/api/reviews/admin")

@PreAuthorize("hasRole('ADMIN')")
public class AdminReviewController {

    @Autowired
    private ReviewService service;

    @GetMapping("/pending")
    public Page<ReviewResponseDTO> pending(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return service.pending(page, size);
    }

    @PatchMapping("/{id}/approve")
    public ReviewResponseDTO approve(
            @PathVariable String id,
            @RequestBody(required = false) @Valid ModerationDTO dto,
            Principal principal
    ) {
        return service.approve(id, principal.getName(), dto);
    }

    @PatchMapping("/{id}/reject")
    public ReviewResponseDTO reject(
            @PathVariable String id,
            @RequestBody(required = false) @Valid ModerationDTO dto,
            Principal principal
    ) {
        return service.reject(id, principal.getName(), dto);
    }
}
