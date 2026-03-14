package com.rihla.reservationservice.mapper;

import com.rihla.reservationservice.DTO.ReservationResponse;
import com.rihla.reservationservice.entity.Reservation;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface ReservationMapper {
    @Mapping(target = "status", expression = "java(r.getStatus().name())")

    ReservationResponse toDto(Reservation r);
}
