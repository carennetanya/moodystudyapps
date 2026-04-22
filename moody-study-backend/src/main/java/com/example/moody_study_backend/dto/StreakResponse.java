package com.example.moody_study_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class StreakResponse {
    private int currentStreak;
    private int longestStreak;
    private int generateQuota;
    private String lastStudyDate;
}