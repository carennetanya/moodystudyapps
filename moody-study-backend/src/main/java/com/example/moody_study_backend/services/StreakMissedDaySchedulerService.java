package com.example.moody_study_backend.services;

import java.time.LocalDate;
import java.util.List;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.moody_study_backend.entity.AwardLevelUp;
import com.example.moody_study_backend.entity.Streak;
import com.example.moody_study_backend.enums.StreakLevel;
import com.example.moody_study_backend.repository.AwardLevelUpRepository;
import com.example.moody_study_backend.repository.StreakRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class StreakMissedDaySchedulerService {

    private final StreakRepository streakRepository;
    private final StudySessionRepository studySessionRepository;
    private final AwardLevelUpRepository awardLevelUpRepository;

    /**
     * Jalankan tiap hari pukul 00:05.
     * Kurangi 1 life untuk setiap user yang tidak belajar kemarin,
     * tapi hanya jika belum dikurangi hari ini (guard lastLifeDeductedDate).
     */
    @Scheduled(cron = "0 5 0 * * *")
    @Transactional
    public void decrementLifeForMissedDays() {
        LocalDate today = LocalDate.now();
        LocalDate yesterday = today.minusDays(1);

        // Ambil semua streak yang:
        // 1. lastStudyDate sebelum kemarin (alias bolos kemarin)
        // 2. masih punya life > 0
        List<Streak> overdueStreaks = streakRepository
                .findByLastStudyDateBeforeAndLifeGreaterThan(yesterday, 0);

        if (overdueStreaks.isEmpty()) {
            log.info("Tidak ada user yang perlu dikurangi life-nya.");
            return;
        }

        int count = 0;
        for (Streak streak : overdueStreaks) {
            // Guard: jangan kurangi 2x di hari yang sama
            if (today.equals(streak.getLastLifeDeductedDate())) {
                log.info("Skip user {} — sudah dikurangi hari ini.",
                        streak.getUser().getEmail());
                continue;
            }

            int lifeBefore = streak.getLife();
            int newLife = Math.max(0, lifeBefore - 1);
            streak.setLife(newLife);
            streak.setLastLifeDeductedDate(today);

            // Jika nyawa habis dan bukan BEGINNER → level turun
            if (newLife == 0) {
                int totalSessions = (int) studySessionRepository.countByUser(streak.getUser());
                StreakLevel currentLevel = mapLevelByTotalSessions(totalSessions);
                if (currentLevel != StreakLevel.BEGINNER) {
                    // Reset life ke 3
                    streak.setLife(3);
                    // Hapus award level sekarang supaya bisa didapat lagi
                    int levelNum = levelToIndex(currentLevel);
                    awardLevelUpRepository
                            .findByUserAndLevel(streak.getUser(), levelNum)
                            .ifPresent(awardLevelUpRepository::delete);
                    log.info("User {} level turun dari {} karena nyawa habis.",
                            streak.getUser().getEmail(), currentLevel);
                }
            }

            streakRepository.save(streak);
            log.info("Life dikurangi untuk user {}: {} -> {}",
                    streak.getUser().getEmail(), lifeBefore, streak.getLife());
            count++;
        }

        log.info("Scheduler selesai: {} user dikurangi life-nya.", count);
    }

    // ── Helpers (duplikasi kecil supaya tidak ada circular dependency) ──

    private StreakLevel mapLevelByTotalSessions(int sessions) {
        if (sessions >= 33) return StreakLevel.MASTER;
        if (sessions >= 22) return StreakLevel.EXPERT;
        if (sessions >= 13) return StreakLevel.PRACTITIONER;
        if (sessions >= 6)  return StreakLevel.LEARNER;
        return StreakLevel.BEGINNER;
    }

    private int levelToIndex(StreakLevel level) {
        return switch (level) {
            case BEGINNER     -> 0;
            case LEARNER      -> 1;
            case PRACTITIONER -> 2;
            case EXPERT       -> 3;
            case MASTER       -> 4;
        };
    }
}