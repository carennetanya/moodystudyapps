package com.example.moody_study_backend.dto;

import com.example.moody_study_backend.enums.StreakLevel;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class StreakResponse {
    private int currentStreak;
    private String lastStudyDate;
    private int life;
    private StreakLevel level;
    private int totalSessions;
    private int sessionsToNextLevel;
    private String nextLevelName;

    // Level-up info (only meaningful after completeSession)
    private StreakLevel previousLevel;
    private boolean leveledUp;
    private int totalCoins; // Total Coin yang dimiliki user (bisa dipakai di Shop)
}