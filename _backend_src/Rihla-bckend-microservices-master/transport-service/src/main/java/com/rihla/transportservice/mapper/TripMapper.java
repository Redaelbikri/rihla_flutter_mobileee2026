package com.rihla.transportservice.mapper;

import com.rihla.transportservice.dto.TripRequest;
import com.rihla.transportservice.dto.TripResponse;
import com.rihla.transportservice.entity.Trip;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface TripMapper {

    TripResponse toDto(Trip trip);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "availableSeats", ignore = true)
    Trip toEntity(TripRequest req);
}
