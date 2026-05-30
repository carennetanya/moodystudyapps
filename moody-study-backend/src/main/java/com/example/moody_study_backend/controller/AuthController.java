package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.dto.AuthResponse;
import com.example.moody_study_backend.dto.LoginRequest;
import com.example.moody_study_backend.dto.RegisterRequest;
import com.example.moody_study_backend.dto.UpdateEmailRequest;
import com.example.moody_study_backend.dto.UpdatePasswordRequest;
import com.example.moody_study_backend.services.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PutMapping("/update-email")
    public ResponseEntity<Map<String, String>> updateEmail(
            @Valid @RequestBody UpdateEmailRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(authService.updateEmail(authentication.getName(), request));
    }

    @PutMapping("/update-password")
    public ResponseEntity<Map<String, String>> updatePassword(
            @Valid @RequestBody UpdatePasswordRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(authService.updatePassword(authentication.getName(), request));
    }
}