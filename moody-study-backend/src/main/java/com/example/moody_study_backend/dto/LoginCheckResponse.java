package com.example.moody_study_backend.dto;

import com.example.moody_study_backend.enums.StreakLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginCheckResponse {
    private int currentLife;          // nyawa sekarang setelah dihitung bolos
    private int livesLost;            // berapa nyawa yang hilang sejak login terakhir
    private long daysSkipped;         // berapa hari bolos
    private boolean leveledDown;      // apakah level turun
    private StreakLevel previousLevel;// level sebelum turun
    private StreakLevel currentLevel; // level sekarang
    private int currentStreak;
    private int sessionsToRecoverLife; // sesi yang dibutuhkan untuk pulihkan 1 nyawa
    private int sessionsCompletedToday;// sesi yang sudah selesai hari ini (untuk progress recovery)
}