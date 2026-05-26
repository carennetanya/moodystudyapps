package com.example.moody_study_backend.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserXp;
import com.example.moody_study_backend.repository.UserRepository;
import com.example.moody_study_backend.repository.UserXpRepository;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UserXpController {

    private final UserXpRepository userXpRepository;
    private final UserRepository userRepository;

    @GetMapping("/xp")
    public ResponseEntity<Map<String, Integer>> getTotalXp(Authentication authentication) {
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        int totalXp = userXpRepository.findByUser(user)
                .map(UserXp::getTotalXp)
                .orElse(0);

        return ResponseEntity.ok(Map.of("totalXp", totalXp));
    }
}