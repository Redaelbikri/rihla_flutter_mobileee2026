package com.rihla.userservice.controller;

import com.rihla.userservice.dto.UpdateProfileRequest;
import com.rihla.userservice.dto.UserRequest;
import com.rihla.userservice.dto.UserResponse;
import com.rihla.userservice.entity.User;
import com.rihla.userservice.mapper.UserMapper;
import com.rihla.userservice.repository.UserRepository;
import com.rihla.userservice.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @Autowired private UserService userService;
    @Autowired private UserMapper userMapper;
    @Autowired private UserRepository userRepository;


    @GetMapping("/me")
    public ResponseEntity<UserResponse> me(Authentication authentication) {
        String email = authentication.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return ResponseEntity.ok(userMapper.toDto(user));
    }

    @PutMapping("/me")
    public ResponseEntity<UserResponse> updateMe(
            Authentication authentication,
            @Valid @RequestBody UpdateProfileRequest req
    ) {
        String email = authentication.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setNom(req.getNom());
        user.setPrenom(req.getPrenom());
        user.setTelephone(req.getTelephone());

        User saved = userRepository.save(user);
        return ResponseEntity.ok(userMapper.toDto(saved));
    }

    @PostMapping
    public ResponseEntity<UserResponse> createUserAdmin(@Valid @RequestBody UserRequest request) {

        User userEntity = userMapper.toEntity(request);


        User savedUser = userService.createUser(userEntity);

        return ResponseEntity.ok(userMapper.toDto(savedUser));
    }

    @GetMapping
    public ResponseEntity<List<UserResponse>> getAllUsers() {
        List<UserResponse> users = userService.getAllUsers().stream()
                .map(userMapper::toDto)
                .toList();
        return ResponseEntity.ok(users);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> getUserById(@PathVariable String id) {
        return userService.getUserById(id)
                .map(userMapper::toDto)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<UserResponse> updateUserAdmin(@PathVariable String id,
                                                        @Valid @RequestBody UserRequest request) {
        User userDetails = userMapper.toEntity(request);
        User updatedUser = userService.updateUser(id, userDetails);
        return ResponseEntity.ok(userMapper.toDto(updatedUser));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable String id) {
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }
}
