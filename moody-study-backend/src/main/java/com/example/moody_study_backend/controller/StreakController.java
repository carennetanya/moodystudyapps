package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.dto.StreakResponse;
import com.example.moody_study_backend.dto.StudySessionRequest;
import com.example.moody_study_backend.services.StreakService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/streak")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StreakController {

    private final StreakService streakService;

    @GetMapping
    public ResponseEntity<StreakResponse> getStreak(Authentication authentication) {
        return ResponseEntity.ok(streakService.getStreak(authentication.getName()));
    }

    @PostMapping("/complete")
    public ResponseEntity<StreakResponse> completeSession(
            @Valid @RequestBody StudySessionRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(
                streakService.completeSession(authentication.getName(), request)
        );
    }
}