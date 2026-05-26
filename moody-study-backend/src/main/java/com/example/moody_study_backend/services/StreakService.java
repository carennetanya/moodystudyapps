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

    // ── XP helpers ─────────────────────────────────────────────────

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

        boolean alreadyAwarded = awardLevelUpRepository
                .findByUserAndLevel(user, levelNumber)
                .isPresent();
        if (alreadyAwarded) return 0;

        int xpBonus = LEVEL_UP_XP[levelNumber - 1];

        AwardLevelUp award = new AwardLevelUp();
        award.setUser(user);
        award.setLevel(levelNumber);
        award.setSummaryCountThreshold(totalSessions);
        award.setXpPoints(xpBonus);
        award.setAwardedAt(LocalDateTime.now());
        awardLevelUpRepository.save(award);

        addXp(user, xpBonus);
        return xpBonus;
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
            getTotalXp(user)
        );
    }

    // ── Complete Session ────────────────────────────────────────────

    @Transactional
    public StreakResponse completeSession(String email, StudySessionRequest request) {
        User user = getUser(email);

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

        if (last == null || last.isEqual(today)) {
            // Sesi pertama atau belajar lagi hari ini — streak tetap
            if (last == null) streak.setCurrentStreak(1);
        } else if (last.isEqual(today.minusDays(1))) {
            // Berturut-turut — streak naik
            streak.setCurrentStreak(streak.getCurrentStreak() + 1);
        } else {
            // Bolos sebelumnya tapi sekarang belajar lagi — streak lanjut
            // TIDAK mengurangi life di sini — itu sudah ditangani oleh
            // StreakMissedDaySchedulerService (tiap malam) dan checkLogin.
            streak.setCurrentStreak(streak.getCurrentStreak() + 1);
        }

        streak.setLastStudyDate(today);

        // Pemulihan life: setiap 2 sesi hari ini → +1 life (max 3)
        long todaySessionCount = studySessionRepository.countByUserAndStartTimeBetween(
            user,
            today.atStartOfDay(),
            today.plusDays(1).atStartOfDay()
        );
        // +1 di sesi ke-2, ke-4, ke-6, dst (setiap kelipatan 2)
        if (todaySessionCount >= 2 && todaySessionCount % 2 == 0 && streak.getLife() < 3) {
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
            levelUpBonusXp
        );
    }

    // ── Check Login ─────────────────────────────────────────────────

    /**
     * Dipanggil saat user login. Cek apakah user bolos dan update life/level.
     *
     * Desain life deduction:
     * - StreakMissedDaySchedulerService: kurangi 1 life tiap malam 00:05
     *   untuk user yang sudah bolos, lalu set lastLifeDeductedDate = today.
     * - checkLogin: kurangi life hanya jika scheduler belum jalan hari ini
     *   (lastLifeDeductedDate != today). Ini cover kasus user login sebelum
     *   scheduler sempat jalan (misal tepat setelah tengah malam).
     *
     * Dengan guard ini, total pengurangan tidak pernah dobel.
     */
    @Transactional
    public LoginCheckResponse checkLogin(String email) {
        User user = getUser(email);
        LocalDate today = LocalDate.now();

        Streak streak = streakRepository.findByUser(user)
            .orElseGet(() -> {
                // User baru — buat & simpan streak awal
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

        boolean userBolос = last != null && last.isBefore(today.minusDays(1));

        if (userBolос) {
            daysSkipped = last.until(today, ChronoUnit.DAYS) - 1;

            // Guard: cek apakah scheduler sudah kurangi life hari ini
            boolean schedulerAlreadyRan = today.equals(streak.getLastLifeDeductedDate());

            if (!schedulerAlreadyRan) {
                // Scheduler belum jalan — kita yang kurangi
                int oldLife = streak.getLife();
                int newLife = (int) Math.max(0, oldLife - daysSkipped);
                livesLost = oldLife - newLife;

                if (livesLost > 0) {
                    streak.setLife(newLife);
                    streak.setLastLifeDeductedDate(today);

                    // Jika nyawa habis dan bukan level BEGINNER → level turun
                    if (newLife == 0 && previousLevel != StreakLevel.BEGINNER) {
                        leveledDown = true;
                        currentLevel = getPreviousLevel(previousLevel);
                        // Reset life ke 3
                        streak.setLife(3);
                        // Hapus award level sekarang supaya bisa didapat lagi
                        int prevLevelNum = levelToIndex(previousLevel);
                        awardLevelUpRepository
                            .findByUserAndLevel(user, prevLevelNum)
                            .ifPresent(awardLevelUpRepository::delete);
                    }

                    streakRepository.save(streak);
                }
            } else {
                // Scheduler sudah kurangi life hari ini — hitung livesLost
                // dari selisih hari bolos vs life sebelumnya, cukup laporkan ke frontend.
                // Kita hitung livesLost dari daysSkipped (max 1 per hari karena scheduler
                // hanya kurangi 1 per run), sudah dilakukan scheduler.
                livesLost = (int) Math.min(daysSkipped, 1);

                // Cek apakah life saat ini sudah 0 → level down sudah ditangani scheduler
                // Kita hanya perlu melaporkan currentLevel yang benar
                if (streak.getLife() == 3 && previousLevel != StreakLevel.BEGINNER) {
                    // Life sudah direset ke 3 → artinya scheduler sudah turunkan level
                    // Ambil level aktual berdasarkan totalSessions (tidak berubah)
                    // Level down sudah terjadi, cukup laporkan
                    leveledDown = true;
                    currentLevel = getPreviousLevel(previousLevel);
                }
            }
        }

        // Hitung sesi hari ini untuk progress recovery
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