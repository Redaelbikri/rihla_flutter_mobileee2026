package com.rihla.reservationservice.repository;

import com.rihla.reservationservice.entity.Reservation;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface ReservationRepository extends MongoRepository<Reservation, String> {
    List<Reservation> findByUserSubjectOrderByCreatedAtDesc(String userSubject);
}
