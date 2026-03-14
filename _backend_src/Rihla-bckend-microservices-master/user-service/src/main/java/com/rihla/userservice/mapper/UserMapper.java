package com.rihla.userservice.mapper;

import com.rihla.userservice.dto.UserRequest;
import com.rihla.userservice.dto.UserResponse;
import com.rihla.userservice.entity.User;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface UserMapper {


    UserResponse toDto(User user);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "dateCreation", ignore = true)
    @Mapping(target = "statut", ignore = true)       // Set by constructor
    User toEntity(UserRequest request);
}