package com.rihla.reservationservice.controller;

import com.rihla.reservationservice.DTO.ReservationRequest;
import com.rihla.reservationservice.DTO.ReservationResponse;
import com.rihla.reservationservice.entity.Reservation;
import com.rihla.reservationservice.mapper.ReservationMapper;
import com.rihla.reservationservice.service.ReservationService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

import static org.springframework.http.HttpStatus.UNAUTHORIZED;

@RestController
@RequestMapping("/api/reservations")
public class ReservationController {

    private final ReservationService service;
    private final ReservationMapper mapper;

    public ReservationController(ReservationService service, ReservationMapper mapper) {
        this.service = service;
        this.mapper = mapper;
    }

    private String subject() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }

    private boolean isAdmin() {
        return SecurityContextHolder.getContext().getAuthentication().getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }

    private String bearer(HttpServletRequest request) {
        String h = request.getHeader("Authorization");
        if (h == null || !h.startsWith("Bearer ")) {
            throw new ResponseStatusException(UNAUTHORIZED, "Missing Bearer token");
        }
        return h;
    }

    @PostMapping
    @PreAuthorize("hasRole('USER')")
    public ReservationResponse create(@Valid @RequestBody ReservationRequest req) {
        Reservation r = service.create(req, subject());
        return mapper.toDto(r);
    }


    @GetMapping("/me")
    @PreAuthorize("hasRole('USER')")
    public List<ReservationResponse> me() {
        return service.myReservations(subject()).stream().map(mapper::toDto).toList();
    }

    @PutMapping("/{id}/cancel")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ReservationResponse cancel(@PathVariable String id) {
        return mapper.toDto(service.cancel(id, subject(), isAdmin()));
    }

    @GetMapping("/admin/all")
    @PreAuthorize("hasRole('ADMIN')")
    public List<ReservationResponse> all() {
        return service.allReservations().stream().map(mapper::toDto).toList();
    }


}
