package com.rihla.hebergementservice.mapper;

import com.rihla.hebergementservice.dto.HebergementRequest;
import com.rihla.hebergementservice.dto.HebergementResponse;
import com.rihla.hebergementservice.entity.Hebergement;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface HebergementMapper {
    HebergementResponse toDto(Hebergement h);

    @Mapping(target="id", ignore = true)
    Hebergement toEntity(HebergementRequest req);
}
