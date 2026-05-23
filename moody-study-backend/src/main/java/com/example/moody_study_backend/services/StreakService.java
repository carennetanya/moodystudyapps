package com.example.moody_study_backend.services;

import java.time.LocalDate;
import java.time.LocalDateTime;

import org.springframework.stereotype.Service;

import com.example.moody_study_backend.dto.StreakResponse;
import com.example.moody_study_backend.dto.StudySessionRequest;
import com.example.moody_study_backend.entity.AwardLevelUp;
import com.example.moody_study_backend.entity.Streak;
import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserXp;
import com.example.moody_study_backend.enums.StreakLevel;
import com.example.moody_study_backend.repository.AwardLevelUpRepository;
import com.example.moody_study_backend.repository.StreakRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;
import com.example.moody_study_backend.repository.UserXpRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class StreakService {

    private final StreakRepository streakRepository;
    private final StudySessionRepository studySessionRepository;
    private final UserRepository userRepository;
    private final DailyQuestService dailyQuestService;
    private final UserXpRepository userXpRepository;
    private final AwardLevelUpRepository awardLevelUpRepository;

    // XP bonus saat naik level — urutan: ke Level 2, 3, 4, 5
    private static final int[] LEVEL_UP_XP = {50, 100, 200, 400};

    private StreakLevel mapLevelByTotalSessions(int sessions) {
        if (sessions >= 33) return StreakLevel.MASTER;
        if (sessions >= 22) return StreakLevel.EXPERT;
        if (sessions >= 13) return StreakLevel.PRACTITIONER;
        if (sessions >= 6)  return StreakLevel.LEARNER;
        return StreakLevel.BEGINNER;
    }

    private int nextLevelThreshold(StreakLevel level) {
        return switch (level) {
            case BEGINNER      -> 6;
            case LEARNER       -> 13;
            case PRACTITIONER  -> 22;
            case EXPERT        -> 33;
            case MASTER        -> Integer.MAX_VALUE;
        };
    }

    private StreakLevel getNextLevel(StreakLevel level) {
        return switch (level) {
            case BEGINNER     -> StreakLevel.LEARNER;
            case LEARNER      -> StreakLevel.PRACTITIONER;
            case PRACTITIONER -> StreakLevel.EXPERT;
            case EXPERT       -> StreakLevel.MASTER;
            case MASTER       -> StreakLevel.MASTER;
        };
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

    private void addXp(User user, int xp) {
        UserXp userXp = userXpRepository.findByUser(user)
                .orElse(UserXp.builder().user(user).totalXp(0).build());
        userXp.setTotalXp(userXp.getTotalXp() + xp);
        userXpRepository.save(userXp);
    }

    private int getTotalXp(User user) {
        return userXpRepository.findByUser(user)
                .map(UserXp::getTotalXp)
                .orElse(0);
    }

    /**
     * Simpan award ke tabel award_level_up saat user naik level.
     * Cek dulu apakah award untuk level ini sudah pernah diberikan
     * (guard supaya tidak double insert).
     */
    private int grantLevelUpAward(User user, StreakLevel newLevel, int totalSessions) {
        int levelNumber = levelToIndex(newLevel);
        if (levelNumber == 0) return 0; // BEGINNER tidak dapat award

        // Cek sudah pernah dapat award level ini belum
        boolean alreadyAwarded = awardLevelUpRepository
                .findByUserAndLevel(user, levelNumber)
                .isPresent();
        if (alreadyAwarded) return 0;

        int xpBonus = LEVEL_UP_XP[levelNumber - 1]; // index 0 = naik ke level 2

        AwardLevelUp award = new AwardLevelUp();
        award.setUser(user);
        award.setLevel(levelNumber);
        award.setSummaryCountThreshold(totalSessions);
        award.setXpPoints(xpBonus);
        award.setAwardedAt(LocalDateTime.now());
        awardLevelUpRepository.save(award);

        // Tambah XP bonus naik level ke user
        addXp(user, xpBonus);
        return xpBonus;
    }

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

        int totalSessions = (int) studySessionRepository.countByUser(user);
        StreakLevel level = mapLevelByTotalSessions(totalSessions);
        int threshold = nextLevelThreshold(level);
        int sessionsToNext = level == StreakLevel.MASTER ? 0 : Math.max(0, threshold - totalSessions);

        return new StreakResponse(
            streak.getCurrentStreak(),
            streak.getLastStudyDate() != null ? streak.getLastStudyDate().toString() : null,
            streak.getLife(),
            level,
            totalSessions,
            sessionsToNext,
            level == StreakLevel.MASTER ? "MASTER" : getNextLevel(level).name(),
            level,   // previousLevel same as current for GET
            false,   // leveledUp
            getTotalXp(user)
        );
    }

    public StreakResponse completeSession(String email, StudySessionRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        // Catat level sebelum sesi
        int sessionsBefore = (int) studySessionRepository.countByUser(user);
        StreakLevel levelBefore = mapLevelByTotalSessions(sessionsBefore);

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
            streak.setCurrentStreak(1);
        } else if (last.isEqual(today.minusDays(1))) {
            streak.setCurrentStreak(streak.getCurrentStreak() + 1);
        } else if (last.isBefore(today.minusDays(1))) {
            if (streak.getLife() == 0) {
                streak.setCurrentStreak(1);
            }
        }

        streak.setLastStudyDate(today);

        // Pemulihan life
        long todaySessionCount = studySessionRepository.countByUserAndStartTimeBetween(
            user,
            today.atStartOfDay(),
            today.plusDays(1).atStartOfDay()
        );
        if (todaySessionCount >= 2 && streak.getLife() < 3) {
            streak.setLife(streak.getLife() + 1);
        }

        streakRepository.save(streak);

        // Evaluasi daily quest
        dailyQuestService.evaluateAfterSession(email, session);

        // Tambah base XP per sesi selesai (10 XP)
        addXp(user, 10);

        // Hitung level setelah sesi
        int totalSessions = (int) studySessionRepository.countByUser(user);
        StreakLevel levelAfter = mapLevelByTotalSessions(totalSessions);
        boolean leveledUp = !levelAfter.equals(levelBefore);

        // Jika naik level → simpan otomatis ke tabel award_level_up
        int levelUpBonusXp = 0;
        if (leveledUp) {
            levelUpBonusXp = grantLevelUpAward(user, levelAfter, totalSessions);
        }

        int threshold = nextLevelThreshold(levelAfter);
        int sessionsToNext = levelAfter == StreakLevel.MASTER ? 0 : Math.max(0, threshold - totalSessions);

        return new StreakResponse(
            streak.getCurrentStreak(),
            streak.getLastStudyDate().toString(),
            streak.getLife(),
            levelAfter,
            totalSessions,
            sessionsToNext,
            levelAfter == StreakLevel.MASTER ? "MASTER" : getNextLevel(levelAfter).name(),
            levelBefore,
            leveledUp,
            levelUpBonusXp  // XP bonus naik level (50/100/200/400)
        );
    }
}