package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.UserRepository;
import com.example.moody_study_backend.dto.UpdateAccountRequest;
import com.example.moody_study_backend.services.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UserController {

    private final UserRepository userRepository;
    private final UserService userService;

    @GetMapping("/me")
    public ResponseEntity<?> getProfile(Authentication authentication) {
        String email = authentication.getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        return ResponseEntity.ok(java.util.Map.of(
                "name", user.getName(),
                "email", user.getEmail(),
                "role", user.getRole().name()
        ));
    }

    @PatchMapping("/update")
    public ResponseEntity<?> updateAccount(
            @RequestBody UpdateAccountRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(
                userService.updateAccount(authentication.getName(), request)
        );
    }
}