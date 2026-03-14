package com.rihla.reservationservice.service;

import com.rihla.reservationservice.DTO.CreateReservationItem;
import com.rihla.reservationservice.DTO.ReservationRequest;
import com.rihla.reservationservice.client.EventClient;
import com.rihla.reservationservice.client.HebergementClient;
import com.rihla.reservationservice.client.TransportClient;
import com.rihla.reservationservice.entity.Reservation;
import com.rihla.reservationservice.entity.ReservationStatus;
import com.rihla.reservationservice.kafka.DomainEvent;
import com.rihla.reservationservice.kafka.ReservationEventProducer;
import com.rihla.reservationservice.repository.ReservationRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;

import static org.springframework.http.HttpStatus.*;

@Service
public class ReservationService {

    private final ReservationRepository repo;
    private final TransportClient transportClient;
    private final HebergementClient hebergementClient;
    private final EventClient eventClient;
    private final ReservationEventProducer producer;

    public ReservationService(ReservationRepository repo,
                              TransportClient transportClient,
                              HebergementClient hebergementClient,
                              EventClient eventClient,
                              ReservationEventProducer producer) {
        this.repo = repo;
        this.transportClient = transportClient;
        this.hebergementClient = hebergementClient;
        this.eventClient = eventClient;
        this.producer = producer;
    }

    // ✅ Create reservation WITHOUT reducing stock now
    public Reservation create(ReservationRequest req, String userSubject) {
        if (req == null || (req.transport == null && req.hebergement == null && req.event == null)) {
            throw new ResponseStatusException(BAD_REQUEST, "Provide at least one item (transport/hebergement/event)");
        }
        if (req.transport != null) validate(req.transport, "transport");
        if (req.hebergement != null) validate(req.hebergement, "hebergement");
        if (req.event != null) validate(req.event, "event");

        // 1) CHECK availability (still ok)
        if (req.transport != null) {
            Boolean ok = transportClient.check(req.transport.id, req.transport.quantity);
            if (ok == null || !ok) throw new ResponseStatusException(BAD_REQUEST, "Transport not available");
        }
        if (req.hebergement != null) {
            Boolean ok = hebergementClient.check(req.hebergement.id, req.hebergement.quantity);
            if (ok == null || !ok) throw new ResponseStatusException(BAD_REQUEST, "Hebergement not available");
        }
        if (req.event != null) {
            Boolean ok = eventClient.check(req.event.id, req.event.quantity);
            if (ok == null || !ok) throw new ResponseStatusException(BAD_REQUEST, "Event not available");
        }

        // 2) SAVE reservation as PENDING_PAYMENT
        Reservation r = new Reservation();
        r.setUserSubject(userSubject);
        r.setStatus(ReservationStatus.PENDING_PAYMENT);
        r.setPaymentStatus("PENDING");
        r.setCreatedAt(LocalDateTime.now());

        if (req.transport != null) {
            r.setTransportTripId(req.transport.id);
            r.setTransportSeats(req.transport.quantity);
        }
        if (req.hebergement != null) {
            r.setHebergementId(req.hebergement.id);
            r.setHebergementRooms(req.hebergement.quantity);
        }
        if (req.event != null) {
            r.setEventId(req.event.id);
            r.setEventTickets(req.event.quantity);
        }

        Reservation saved = repo.save(r);

        // 3) Publish "reservation created" (notification-service listens)
        DomainEvent evt = DomainEvent.builder()
                .eventId(saved.getId())
                .eventType("RESERVATION_CREATED")
                .userSubject(userSubject)
                .message("Reservation created. Waiting for payment.")
                .createdAt(LocalDateTime.now())
                .build();

        try { producer.publishConfirmed(evt); } catch (Exception ignored) {}

        return saved;
    }

    public void onPaymentSucceeded(String reservationId) {
        Reservation r = repo.findById(reservationId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Reservation not found"));

        // idempotent
        if (r.getStatus() == ReservationStatus.CONFIRMED) return;
        if (r.getStatus() == ReservationStatus.CANCELLED) return;

        try {
            if (r.getTransportTripId() != null) {
                transportClient.reduceInternal(r.getTransportTripId(), r.getTransportSeats());
            }
            if (r.getHebergementId() != null) {
                hebergementClient.reduceInternal(r.getHebergementId(), r.getHebergementRooms());
            }
            if (r.getEventId() != null) {
                eventClient.reduceInternal(r.getEventId(), r.getEventTickets());
            }
        } catch (Exception e) {
            // If stock reduce fails AFTER payment success, mark reservation cancelled to avoid ghost reservations
            r.setStatus(ReservationStatus.CANCELLED);
            r.setPaymentStatus("SUCCEEDED_BUT_STOCK_FAILED");
            repo.save(r);
            throw new ResponseStatusException(BAD_GATEWAY, "Payment ok but stock update failed");
        }

        r.setStatus(ReservationStatus.CONFIRMED);
        r.setPaymentStatus("SUCCEEDED");
        repo.save(r);

        DomainEvent evt = DomainEvent.builder()
                .eventId(r.getId())
                .eventType("RESERVATION_CONFIRMED")
                .userSubject(r.getUserSubject())
                .message("Reservation confirmed after payment.")
                .createdAt(LocalDateTime.now())
                .build();

        try { producer.publishConfirmed(evt); } catch (Exception ignored) {}
    }

    public void onPaymentFailed(String reservationId) {
        Reservation r = repo.findById(reservationId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Reservation not found"));

        // idempotent
        if (r.getStatus() == ReservationStatus.CANCELLED) return;

        r.setStatus(ReservationStatus.CANCELLED);
        r.setPaymentStatus("FAILED");
        repo.save(r);

        DomainEvent evt = DomainEvent.builder()
                .eventId(r.getId())
                .eventType("RESERVATION_CANCELLED")
                .userSubject(r.getUserSubject())
                .message("Reservation cancelled (payment failed).")
                .createdAt(LocalDateTime.now())
                .build();

        try { producer.publishConfirmed(evt); } catch (Exception ignored) {}
    }

    public List<Reservation> myReservations(String userSubject) {
        return repo.findByUserSubjectOrderByCreatedAtDesc(userSubject);
    }

    public List<Reservation> allReservations() {
        return repo.findAll();
    }

    public Reservation cancel(String reservationId, String userSubject, boolean isAdmin) {
        Reservation r = repo.findById(reservationId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Reservation not found"));

        if (!isAdmin && !r.getUserSubject().equals(userSubject)) {
            throw new ResponseStatusException(FORBIDDEN, "Not your reservation");
        }

        r.setStatus(ReservationStatus.CANCELLED);
        return repo.save(r);
    }

    private void validate(CreateReservationItem item, String name) {
        if (item.id == null || item.id.isBlank())
            throw new ResponseStatusException(BAD_REQUEST, name + ".id is required");
        if (item.quantity <= 0)
            throw new ResponseStatusException(BAD_REQUEST, name + ".quantity must be > 0");
    }
}
