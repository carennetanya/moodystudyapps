package com.example.moody_study_backend.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserCoin;
import com.example.moody_study_backend.repository.UserRepository;
import com.example.moody_study_backend.repository.UserCoinRepository;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UserCoinController {

    private final UserCoinRepository userCoinRepository;
    private final UserRepository userRepository;

    /**
     * GET /api/user/coins
     * Ambil total coin user yang terkumpul dari daily quest.
     */
    @GetMapping("/coins")
    public ResponseEntity<Map<String, Integer>> getTotalCoins(Authentication authentication) {
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        int totalCoins = userCoinRepository.findByUser(user)
                .map(UserCoin::getTotalCoins)
                .orElse(0);

        return ResponseEntity.ok(Map.of("totalCoins", totalCoins));
    }
}