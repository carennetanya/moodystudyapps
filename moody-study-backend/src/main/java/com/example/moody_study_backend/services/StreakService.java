package com.example.moody_study_backend.services;

import com.example.moody_study_backend.dto.StreakResponse;
import com.example.moody_study_backend.dto.StudySessionRequest;
import com.example.moody_study_backend.entity.Streak;
import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.StreakRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class StreakService {

    private final StreakRepository streakRepository;
    private final StudySessionRepository studySessionRepository;
    private final UserRepository userRepository;

    public StreakResponse getStreak(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        Streak streak = streakRepository.findByUser(user)
                .orElse(Streak.builder()
                        .user(user)
                        .currentStreak(0)
                        .longestStreak(0)
                        .generateQuota(1)
                        .lastStudyDate(null)
                        .build());

        return new StreakResponse(
                streak.getCurrentStreak(),
                streak.getLongestStreak(),
                streak.getGenerateQuota(),
                streak.getLastStudyDate() != null ? streak.getLastStudyDate().toString() : null
        );
    }

    public StreakResponse completeSession(String email, StudySessionRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        // Simpan study session
        StudySession session = StudySession.builder()
                .user(user)
                .mood(request.getMood())
                .location(request.getLocation())
                .durationMinutes(request.getDurationMinutes())
                .focusSeconds(request.getFocusSeconds())
                .distractionSeconds(request.getDistractionSeconds())
                .startTime(LocalDateTime.now().minusMinutes(request.getDurationMinutes()))
                .endTime(LocalDateTime.now())
                .build();

        studySessionRepository.save(session);

        // Update streak
        Streak streak = streakRepository.findByUser(user)
                .orElse(Streak.builder()
                        .user(user)
                        .currentStreak(0)
                        .longestStreak(0)
                        .generateQuota(1)
                        .lastStudyDate(null)
                        .build());

        LocalDate today = LocalDate.now();
        LocalDate last = streak.getLastStudyDate();

        if (last == null || last.isBefore(today.minusDays(1))) {
            // Reset streak
            streak.setCurrentStreak(1);
        } else if (last.isEqual(today.minusDays(1))) {
            // Lanjut streak
            streak.setCurrentStreak(streak.getCurrentStreak() + 1);
        }
        // Kalau last == today, tidak update (sudah belajar hari ini)

        // Update longest streak
        if (streak.getCurrentStreak() > streak.getLongestStreak()) {
            streak.setLongestStreak(streak.getCurrentStreak());
        }

        // Hitung generate quota sesuai proposal
        int current = streak.getCurrentStreak();
        int quota;
        if (current <= 6) {
            quota = current; // hari ke-1 = 1, ke-2 = 2, dst
        } else if (current % 7 == 0) {
            quota = current + 2; // bonus setiap 7 hari
        } else {
            quota = 6 + ((current / 7) * 2); // akumulasi bonus
        }

        streak.setGenerateQuota(quota);
        streak.setLastStudyDate(today);
        streakRepository.save(streak);

        return new StreakResponse(
                streak.getCurrentStreak(),
                streak.getLongestStreak(),
                streak.getGenerateQuota(),
                streak.getLastStudyDate().toString()
        );
    }
}