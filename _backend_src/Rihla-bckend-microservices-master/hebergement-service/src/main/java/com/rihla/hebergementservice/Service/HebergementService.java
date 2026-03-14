package com.rihla.hebergementservice.Service;

import com.rihla.hebergementservice.dto.HebergementRequest;
import com.rihla.hebergementservice.dto.HebergementResponse;
import com.rihla.hebergementservice.entity.Hebergement;
import com.rihla.hebergementservice.entity.HebergementType;
import com.rihla.hebergementservice.mapper.HebergementMapper;
import com.rihla.hebergementservice.repository.HebergementRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class HebergementService {

    private final HebergementRepository repo;
    private final HebergementMapper mapper;

    public HebergementService(HebergementRepository repo, HebergementMapper mapper) {
        this.repo = repo;
        this.mapper = mapper;
    }

    public HebergementResponse create(HebergementRequest req) {
        Hebergement h = mapper.toEntity(req);
        return mapper.toDto(repo.save(h));
    }

    public List<HebergementResponse> getAll() {
        return repo.findAll().stream().map(mapper::toDto).toList();
    }

    public HebergementResponse getById(String id) {
        return repo.findById(id)
                .map(mapper::toDto)
                .orElseThrow(() -> new RuntimeException("Hebergement not found: " + id));
    }

    public HebergementResponse update(String id, HebergementRequest req) {
        Hebergement h = repo.findById(id)
                .orElseThrow(() -> new RuntimeException("Hebergement not found: " + id));

        h.setNom(req.getNom());
        h.setVille(req.getVille());
        h.setAdresse(req.getAdresse());
        h.setType(req.getType());
        h.setPrixParNuit(req.getPrixParNuit());
        h.setChambresDisponibles(req.getChambresDisponibles());
        h.setNote(req.getNote());
        h.setImageUrl(req.getImageUrl());

        return mapper.toDto(repo.save(h));
    }

    public void delete(String id) {
        if (!repo.existsById(id)) throw new RuntimeException("Hebergement not found: " + id);
        repo.deleteById(id);
    }


    public List<HebergementResponse> search(String city, Double maxPrice) {
        if (city != null && maxPrice != null) {
            return repo.findByVilleContainingIgnoreCaseAndPrixParNuitLessThanEqual(city, maxPrice)
                    .stream().map(mapper::toDto).toList();
        }
        if (city != null) {
            return repo.findByVilleContainingIgnoreCase(city).stream().map(mapper::toDto).toList();
        }
        if (maxPrice != null) {
            return repo.findByPrixParNuitLessThanEqual(maxPrice).stream().map(mapper::toDto).toList();
        }
        return getAll();
    }

    public List<HebergementResponse> filterByType(HebergementType type) {
        return repo.findByType(type).stream().map(mapper::toDto).toList();
    }

    // Stock
    public void reduceStock(String id, int qty) {
        Hebergement h = repo.findById(id)
                .orElseThrow(() -> new RuntimeException("Hebergement not found: " + id));

        if (h.getChambresDisponibles() == null || h.getChambresDisponibles() < qty) {
            throw new RuntimeException("Not enough rooms available");
        }
        h.setChambresDisponibles(h.getChambresDisponibles() - qty);
        repo.save(h);
    }

    public boolean checkAvailability(String id, int qty) {
        Hebergement h = repo.findById(id)
                .orElseThrow(() -> new RuntimeException("Hebergement not found: " + id));
        return h.getChambresDisponibles() != null && h.getChambresDisponibles() >= qty;
    }
}
