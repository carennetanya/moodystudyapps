package com.example.moody_study_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import com.example.moody_study_backend.enums.StreakLevel;

@Data
@AllArgsConstructor
public class StreakResponse {
    private int currentStreak;
    private String lastStudyDate;
    private int life;
    private StreakLevel level;
}