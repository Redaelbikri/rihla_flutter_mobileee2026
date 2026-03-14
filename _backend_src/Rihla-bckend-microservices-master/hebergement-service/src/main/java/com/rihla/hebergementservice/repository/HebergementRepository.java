package com.rihla.hebergementservice.repository;

import com.rihla.hebergementservice.entity.Hebergement;
import com.rihla.hebergementservice.entity.HebergementType;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface HebergementRepository extends MongoRepository<Hebergement, String> {

    List<Hebergement> findByVilleContainingIgnoreCase(String ville);

    List<Hebergement> findByType(HebergementType type);

    List<Hebergement> findByPrixParNuitLessThanEqual(Double maxPrice);

    List<Hebergement> findByVilleContainingIgnoreCaseAndPrixParNuitLessThanEqual(String ville, Double maxPrice);
}
