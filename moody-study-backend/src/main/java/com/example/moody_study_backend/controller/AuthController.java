package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.dto.AuthResponse;
import com.example.moody_study_backend.dto.LoginRequest;
import com.example.moody_study_backend.dto.RegisterRequest;
import com.example.moody_study_backend.dto.UpdateEmailRequest;
import com.example.moody_study_backend.dto.UpdatePasswordRequest;
import com.example.moody_study_backend.repository.UserRepository;
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
    private final UserRepository userRepository;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    // Returns AuthResponse with a NEW token — Flutter must store this token
    @PutMapping("/update-email")
    public ResponseEntity<AuthResponse> updateEmail(
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

    @GetMapping("/check-email")
    public ResponseEntity<Map<String, Object>> checkEmail(@RequestParam String email) {
        boolean taken = userRepository.existsByEmailIgnoreCase(email);
        Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("available", !taken);
        if (taken) body.put("reason", "validation.email.taken");
        return ResponseEntity.ok(body);
    }

    @GetMapping("/check-username")
    public ResponseEntity<Map<String, Object>> checkUsername(@RequestParam String username) {
        boolean taken = userRepository.existsByUsernameIgnoreCase(username);
        Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("available", !taken);
        if (taken) body.put("reason", "validation.username.taken");
        return ResponseEntity.ok(body);
    }
}
