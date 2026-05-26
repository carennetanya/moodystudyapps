package com.example.moody_study_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.moody_study_backend.dto.LevelHistoryResponse;
import com.example.moody_study_backend.dto.LoginCheckResponse;
import com.example.moody_study_backend.dto.StreakResponse;
import com.example.moody_study_backend.dto.StudySessionRequest;
import com.example.moody_study_backend.services.LevelHistoryService;
import com.example.moody_study_backend.services.StreakService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/streak")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StreakController {

    private final StreakService streakService;
    private final LevelHistoryService levelHistoryService;

    @GetMapping
    public ResponseEntity<StreakResponse> getStreak(Authentication authentication) {
        return ResponseEntity.ok(streakService.getStreak(authentication.getName()));
    }

    @PostMapping("/check-login")
    public ResponseEntity<LoginCheckResponse> checkLogin(Authentication authentication) {
        return ResponseEntity.ok(streakService.checkLogin(authentication.getName()));
    }

    @GetMapping("/level-history/{level}")
    public ResponseEntity<LevelHistoryResponse> getLevelHistory(
            @PathVariable int level,
            Authentication authentication) {
        return ResponseEntity.ok(
                levelHistoryService.getLevelHistory(authentication.getName(), level)
        );
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