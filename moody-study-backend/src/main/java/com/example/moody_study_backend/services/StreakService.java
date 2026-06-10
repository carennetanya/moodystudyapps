package com.example.moody_study_backend.services;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.moody_study_backend.dto.LoginCheckResponse;
import com.example.moody_study_backend.dto.StreakResponse;
import com.example.moody_study_backend.dto.StudySessionRequest;
import com.example.moody_study_backend.entity.AwardLevelUp;
import com.example.moody_study_backend.entity.Streak;
import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserCoin;
import com.example.moody_study_backend.enums.StreakLevel;
import com.example.moody_study_backend.repository.AwardLevelUpRepository;
import com.example.moody_study_backend.repository.StreakRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;
import com.example.moody_study_backend.repository.UserCoinRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class StreakService {

    private final StreakRepository streakRepository;
    private final StudySessionRepository studySessionRepository;
    private final UserRepository userRepository;
    private final DailyQuestService dailyQuestService;
    private final UserCoinRepository userCoinRepository;
    private final AwardLevelUpRepository awardLevelUpRepository;

    // Coin bonus saat naik level — urutan: ke Level 2, 3, 4, 5
    private static final int[] LEVEL_UP_COINS = {50, 100, 200, 400};

    // ── Level helpers ───────────────────────────────────────────────

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

    private StreakLevel getPreviousLevel(StreakLevel level) {
        return switch (level) {
            case LEARNER      -> StreakLevel.BEGINNER;
            case PRACTITIONER -> StreakLevel.LEARNER;
            case EXPERT       -> StreakLevel.PRACTITIONER;
            case MASTER       -> StreakLevel.EXPERT;
            default           -> StreakLevel.BEGINNER;
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

    // ── Coin helpers ────────────────────────────────────────────────

    private void addCoins(User user, int coins) {
        UserCoin userCoin = userCoinRepository.findByUser(user)
                .orElse(UserCoin.builder().user(user).totalCoins(0).build());
        userCoin.setTotalCoins(userCoin.getTotalCoins() + coins);
        userCoinRepository.save(userCoin);
    }

    private int getTotalCoins(User user) {
        return userCoinRepository.findByUser(user)
                .map(UserCoin::getTotalCoins)
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

        boolean alreadyAwarded = awardLevelUpRepository
                .findByUserAndLevel(user, levelNumber)
                .isPresent();
        if (alreadyAwarded) return 0;

        int coinBonus = LEVEL_UP_COINS[levelNumber - 1];

        AwardLevelUp award = new AwardLevelUp();
        award.setUser(user);
        award.setLevel(levelNumber);
        award.setSummaryCountThreshold(totalSessions);
        award.setCoinPoints(coinBonus);
        award.setAwardedAt(LocalDateTime.now());
        awardLevelUpRepository.save(award);

        addCoins(user, coinBonus);
        return coinBonus;
    }

    // ── Get Streak ──────────────────────────────────────────────────

    public StreakResponse getStreak(String email) {
        User user = getUser(email);

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
            level,
            false,
            getTotalCoins(user)
        );
    }

    // ── Complete Session ────────────────────────────────────────────

    @Transactional
    public StreakResponse completeSession(String email, StudySessionRequest request) {
        User user = getUser(email);

        int sessionsBefore = (int) studySessionRepository.countByUser(user);
        StreakLevel levelBefore = mapLevelByTotalSessions(sessionsBefore);

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

        Streak streak = streakRepository.findByUser(user)
            .orElse(Streak.builder()
                .user(user)
                .currentStreak(0)
                .lastStudyDate(null)
                .life(3)
                .build());

        LocalDate today = LocalDate.now();
        LocalDate last = streak.getLastStudyDate();

        if (last == null || last.isEqual(today)) {
            if (last == null) streak.setCurrentStreak(1);
        } else if (last.isEqual(today.minusDays(1))) {
            streak.setCurrentStreak(streak.getCurrentStreak() + 1);
        } else {
            streak.setCurrentStreak(streak.getCurrentStreak() + 1);
        }

        streak.setLastStudyDate(today);

        // Pemulihan life: setiap 2 sesi hari ini → +1 life (max 3)
        long todaySessionCount = studySessionRepository.countByUserAndStartTimeBetween(
            user,
            today.atStartOfDay(),
            today.plusDays(1).atStartOfDay()
        );
        if (todaySessionCount >= 2 && todaySessionCount % 2 == 0 && streak.getLife() < 3) {
            streak.setLife(streak.getLife() + 1);
        }

        streakRepository.save(streak);

        // Evaluasi daily quest
        dailyQuestService.evaluateAfterSession(email, session);

        // Tambah base coin per sesi selesai (10 Coin)
        addCoins(user, 10);

        int totalSessions = (int) studySessionRepository.countByUser(user);
        StreakLevel levelAfter = mapLevelByTotalSessions(totalSessions);
        boolean leveledUp = !levelAfter.equals(levelBefore);

        int levelUpBonusCoins = 0;
        if (leveledUp) {
            levelUpBonusCoins = grantLevelUpAward(user, levelAfter, totalSessions);
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
            levelUpBonusCoins
        );
    }

    // ── Check Login ─────────────────────────────────────────────────

    @Transactional
    public LoginCheckResponse checkLogin(String email) {
        User user = getUser(email);
        LocalDate today = LocalDate.now();

        Streak streak = streakRepository.findByUser(user)
            .orElseGet(() -> {
                Streak newStreak = Streak.builder()
                    .user(user)
                    .currentStreak(0)
                    .lastStudyDate(null)
                    .life(3)
                    .build();
                return streakRepository.save(newStreak);
            });

        LocalDate last = streak.getLastStudyDate();
        int livesLost = 0;
        boolean leveledDown = false;
        int totalSessions = (int) studySessionRepository.countByUser(user);
        StreakLevel previousLevel = mapLevelByTotalSessions(totalSessions);
        StreakLevel currentLevel = previousLevel;
        long daysSkipped = 0;

        boolean userBolos = last != null && last.isBefore(today.minusDays(1));

        if (userBolos) {
            daysSkipped = last.until(today, ChronoUnit.DAYS) - 1;

            boolean schedulerAlreadyRan = today.equals(streak.getLastLifeDeductedDate());

            if (!schedulerAlreadyRan) {
                int oldLife = streak.getLife();
                int newLife = (int) Math.max(0, oldLife - daysSkipped);
                livesLost = oldLife - newLife;

                if (livesLost > 0) {
                    streak.setLife(newLife);
                    streak.setLastLifeDeductedDate(today);

                    if (newLife == 0 && previousLevel != StreakLevel.BEGINNER) {
                        leveledDown = true;
                        currentLevel = getPreviousLevel(previousLevel);
                        streak.setLife(3);
                        int prevLevelNum = levelToIndex(previousLevel);
                        awardLevelUpRepository
                            .findByUserAndLevel(user, prevLevelNum)
                            .ifPresent(awardLevelUpRepository::delete);
                    }

                    streakRepository.save(streak);
                }
            } else {
                livesLost = (int) Math.min(daysSkipped, 1);

                if (streak.getLife() == 3 && previousLevel != StreakLevel.BEGINNER) {
                    leveledDown = true;
                    currentLevel = getPreviousLevel(previousLevel);
                }
            }
        }

        long todaySessions = studySessionRepository.countByUserAndStartTimeBetween(
            user, today.atStartOfDay(), today.plusDays(1).atStartOfDay()
        );

        return LoginCheckResponse.builder()
            .currentLife(streak.getLife())
            .livesLost(livesLost)
            .daysSkipped(daysSkipped)
            .leveledDown(leveledDown)
            .previousLevel(previousLevel)
            .currentLevel(currentLevel)
            .currentStreak(streak.getCurrentStreak())
            .sessionsToRecoverLife(2)
            .sessionsCompletedToday((int) todaySessions)
            .build();
    }

    // ── Utility ─────────────────────────────────────────────────────

    private User getUser(String email) {
        return userRepository.findByEmail(email)
            .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
    }
}
