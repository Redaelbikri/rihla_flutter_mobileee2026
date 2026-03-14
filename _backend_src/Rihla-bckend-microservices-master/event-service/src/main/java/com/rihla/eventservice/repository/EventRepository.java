package com.rihla.eventservice.repository;

import com.rihla.eventservice.entity.Event;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import java.util.List;

public interface EventRepository extends MongoRepository<Event, String> {


    List<Event> findByCategorie(String categorie);

    List<Event> findByLieuContainingIgnoreCase(String lieu);

    List<Event> findByPrixLessThanEqual(Double maxPrix);

    List<Event> findByNomContainingIgnoreCase(String keyword);
}