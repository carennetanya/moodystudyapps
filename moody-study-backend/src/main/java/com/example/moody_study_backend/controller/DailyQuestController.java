package com.example.moody_study_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.moody_study_backend.dto.DailyQuestResponse;
import com.example.moody_study_backend.services.DailyQuestService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/quest")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class DailyQuestController {

    private final DailyQuestService dailyQuestService;

    /**
     * GET /api/quest/daily
     * Ambil 3 quest harian user (auto-generate jika belum ada).
     * Response sudah include totalXp user.
     */
    @GetMapping("/daily")
    public ResponseEntity<DailyQuestResponse> getDailyQuests(Authentication authentication) {
        return ResponseEntity.ok(
            dailyQuestService.getDailyQuests(authentication.getName())
        );
    }

    /**
     * POST /api/quest/complete-review
     * Tandai quest REVIEW_STATS sebagai selesai (dipanggil saat user membuka halaman statistik).
     */
    @PostMapping("/complete-review")
    public ResponseEntity<DailyQuestResponse> completeReviewStats(Authentication authentication) {
        return ResponseEntity.ok(
            dailyQuestService.completeReviewStats(authentication.getName())
        );
    }
}