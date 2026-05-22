package com.example.moody_study_backend.services;

import java.time.LocalDate;
import java.util.List;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import com.example.moody_study_backend.entity.Streak;
import com.example.moody_study_backend.repository.StreakRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class StreakMissedDaySchedulerService {

    private final StreakRepository streakRepository;

    // Jalankan tiap hari pukul 00:05 untuk mengurangi life pengguna yang melewatkan hari.
    @Scheduled(cron = "0 5 0 * * *")
    public void decrementLifeForMissedDays() {
        LocalDate yesterday = LocalDate.now().minusDays(1);
        List<Streak> overdueStreaks = streakRepository.findByLastStudyDateBeforeAndLifeGreaterThan(yesterday, 0);

        if (overdueStreaks.isEmpty()) {
            return;
        }

        for (Streak streak : overdueStreaks) {
            int lifeBefore = streak.getLife();
            streak.setLife(Math.max(0, lifeBefore - 1));
            streakRepository.save(streak);
            log.info("Life dikurangi untuk user {}: {} -> {}", streak.getUser().getEmail(), lifeBefore, streak.getLife());
        }

        log.info("Decremented life for {} overdue streak(s).", overdueStreaks.size());
    }
}
