package com.example.moody_study_backend.services;

import java.time.LocalDate;
import java.time.LocalDateTime;

import org.springframework.stereotype.Service;

import com.example.moody_study_backend.dto.StreakResponse;
import com.example.moody_study_backend.dto.StudySessionRequest;
import com.example.moody_study_backend.entity.Streak;
import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.enums.StreakLevel;
import com.example.moody_study_backend.repository.StreakRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class StreakService {

    private StreakLevel mapLevel(int streak) {
        if (streak >= 33) return StreakLevel.MASTER;
        if (streak >= 22) return StreakLevel.EXPERT;
        if (streak >= 13) return StreakLevel.PRACTITIONER;
        if (streak >= 6) return StreakLevel.LEARNER;
        return StreakLevel.BEGINNER;
    }

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
                        .lastStudyDate(null)
                        .life(3)
                        .build());

        return new StreakResponse(
            streak.getCurrentStreak(),
            streak.getLastStudyDate() != null ? streak.getLastStudyDate().toString() : null,
            streak.getLife(),
            mapLevel(streak.getCurrentStreak())
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
                .lastStudyDate(null)
                .life(3)
                .build());

        LocalDate today = LocalDate.now();
        LocalDate last = streak.getLastStudyDate();

        if (last == null) {
            // First recorded study session: mulai streak tanpa mengurangi life.
            streak.setCurrentStreak(1);
        } else if (last.isEqual(today.minusDays(1))) {
            // Lanjut streak normal hari berikutnya.
            streak.setCurrentStreak(streak.getCurrentStreak() + 1);
        } else if (last.isBefore(today.minusDays(1))) {
            // User melewatkan satu hari atau lebih.
            // Jika masih ada life, streak tetap sama sampai life habis.
            if (streak.getLife() == 0) {
                streak.setCurrentStreak(1);
            }
        }
        // Kalau last == today, tidak update (sudah belajar hari ini)

        streak.setLastStudyDate(today);

        // Pemulihan life: jika user menyelesaikan 2 sesi dalam sehari, tambah 1 life (maksimal 3)
        long todaySessionCount = studySessionRepository.countByUserAndStartTimeBetween(
            user,
            today.atStartOfDay(),
            today.plusDays(1).atStartOfDay()
        );
        if (todaySessionCount >= 2 && streak.getLife() < 3) {
            streak.setLife(streak.getLife() + 1);
        }

        streakRepository.save(streak);

        return new StreakResponse(
            streak.getCurrentStreak(),
            streak.getLastStudyDate().toString(),
            streak.getLife(),
            mapLevel(streak.getCurrentStreak())
        );
    }
}