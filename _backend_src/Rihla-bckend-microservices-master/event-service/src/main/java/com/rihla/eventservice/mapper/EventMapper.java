package com.rihla.eventservice.mapper;

import com.rihla.eventservice.dto.EventRequest;
import com.rihla.eventservice.dto.EventResponse;
import com.rihla.eventservice.entity.Event;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface EventMapper {
    EventResponse toDto(Event event);

    @Mapping(target = "id", ignore = true)
    Event toEntity(EventRequest request);
}