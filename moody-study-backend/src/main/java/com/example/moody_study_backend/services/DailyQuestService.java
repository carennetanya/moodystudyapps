package com.example.moody_study_backend.services;

import com.example.moody_study_backend.dto.DailyQuestResponse;
import com.example.moody_study_backend.entity.*;
import com.example.moody_study_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DailyQuestService {

    private final DailyQuestRepository dailyQuestRepository;
    private final UserXpRepository userXpRepository;
    private final UserRepository userRepository;
    private final StudySessionRepository studySessionRepository;

    // ──────────────────────────────────────────────
    //  Quest metadata: title, description, XP reward
    // ──────────────────────────────────────────────

    record QuestMeta(String title, String description, int xp) {}

    private static final Map<QuestKey, QuestMeta> QUEST_META = Map.of(
        QuestKey.FIRST_SESSION,
            new QuestMeta("Sesi Pembuka",
                "Selesaikan 1 sesi belajar pertama hari ini (durasi bebas).", 10),
        QuestKey.ZERO_DISTRACTION,
            new QuestMeta("Fokus Sempurna",
                "Selesaikan 1 sesi belajar (min 25 menit) dengan 0 kali distraksi.", 25),
        QuestKey.MARATHON,
            new QuestMeta("Maraton Belajar",
                "Selesaikan total minimal 3 sesi belajar dalam satu hari.", 25),
        QuestKey.LONG_FOCUS,
            new QuestMeta("Fokus Panjang",
                "Selesaikan 1 sesi belajar dengan durasi minimal 30 menit.", 15),
        QuestKey.TOLERANCE_LIMIT,
            new QuestMeta("Batas Toleransi",
                "Selesaikan 1 sesi belajar dengan jumlah distraksi maksimal 2 kali.", 15),
        QuestKey.MORNING_WARRIOR,
            new QuestMeta("Penguasa Pagi",
                "Selesaikan minimal 1 sesi belajar sebelum jam 10:00 pagi.", 15),
        QuestKey.NIGHT_FIGHTER,
            new QuestMeta("Pejuang Malam",
                "Selesaikan minimal 1 sesi belajar di atas jam 19:00 malam.", 15),
        QuestKey.DOUBLE_SESSION,
            new QuestMeta("Sesi Double",
                "Selesaikan 2 sesi belajar berturut-turut dengan jeda istirahat maksimal 10 menit.", 20),
        QuestKey.CONSISTENCY_HOUR,
            new QuestMeta("Konsistensi Jam",
                "Mulai sesi belajar di jam yang sama seperti hari kemarin (toleransi 30 menit).", 20),
        QuestKey.REVIEW_STATS,
            new QuestMeta("Review Statistik",
                "Buka halaman statistik belajar untuk melihat grafik progres minggu ini.", 5)
    );

    // ──────────────────────────────────────────────
    //  GET daily quests (auto-generate if not exist)
    // ──────────────────────────────────────────────

    @Transactional
    public DailyQuestResponse getDailyQuests(String email) {
        User user = getUser(email);
        LocalDate today = LocalDate.now();

        List<DailyQuest> quests = dailyQuestRepository.findByUserAndQuestDate(user, today);

        // Generate quest hari ini jika belum ada
        if (quests.isEmpty()) {
            quests = generateDailyQuests(user, today);
        }

        return buildResponse(today, quests);
    }

    // ──────────────────────────────────────────────
    //  Evaluate & complete quests after a session
    //  Dipanggil otomatis setelah StreakService.completeSession()
    // ──────────────────────────────────────────────

    @Transactional
    public DailyQuestResponse evaluateAfterSession(String email, StudySession latestSession) {
        User user = getUser(email);
        LocalDate today = LocalDate.now();

        List<DailyQuest> quests = dailyQuestRepository.findByUserAndQuestDate(user, today);
        if (quests.isEmpty()) {
            quests = generateDailyQuests(user, today);
        }

        List<StudySession> todaySessions = getTodaySessions(user, today);

        for (DailyQuest quest : quests) {
            if (quest.isCompleted()) continue;

            boolean fulfilled = checkQuestFulfilled(quest.getQuestKey(), latestSession, todaySessions, user);
            if (fulfilled) {
                quest.setCompleted(true);
                dailyQuestRepository.save(quest);
                addXp(user, quest.getXpReward());
            }
        }

        return buildResponse(today, quests);
    }

    // ──────────────────────────────────────────────
    //  Complete REVIEW_STATS quest manually
    // ──────────────────────────────────────────────

    @Transactional
    public DailyQuestResponse completeReviewStats(String email) {
        User user = getUser(email);
        LocalDate today = LocalDate.now();

        List<DailyQuest> quests = dailyQuestRepository.findByUserAndQuestDate(user, today);
        if (quests.isEmpty()) {
            quests = generateDailyQuests(user, today);
        }

        for (DailyQuest quest : quests) {
            if (quest.getQuestKey() == QuestKey.REVIEW_STATS && !quest.isCompleted()) {
                quest.setCompleted(true);
                dailyQuestRepository.save(quest);
                addXp(user, quest.getXpReward());
                break;
            }
        }

        return buildResponse(today, quests);
    }

    // ──────────────────────────────────────────────
    //  Quest evaluation logic
    // ──────────────────────────────────────────────

    private boolean checkQuestFulfilled(
            QuestKey key,
            StudySession latest,
            List<StudySession> todaySessions,
            User user) {

        return switch (key) {
            case FIRST_SESSION ->
                // Cukup 1 sesi hari ini
                !todaySessions.isEmpty();

            case ZERO_DISTRACTION ->
                // Min 25 menit + 0 distraksi (distractionSeconds == 0)
                latest.getDurationMinutes() >= 25 && latest.getDistractionSeconds() == 0;

            case MARATHON ->
                // Min 3 sesi dalam sehari
                todaySessions.size() >= 3;

            case LONG_FOCUS ->
                // Min 30 menit
                latest.getDurationMinutes() >= 30;

            case TOLERANCE_LIMIT ->
                // Distraksi maks 2 kali. 1 distraksi ≈ 30 detik away timer
                // Backend menyimpan distractionSeconds; 1 kejadian = min 30 detik
                countDistractionEvents(latest.getDistractionSeconds()) <= 2;

            case MORNING_WARRIOR ->
                // Sesi dimulai sebelum 10:00
                latest.getStartTime().toLocalTime().isBefore(LocalTime.of(10, 0));

            case NIGHT_FIGHTER ->
                // Sesi dimulai setelah 19:00
                latest.getStartTime().toLocalTime().isAfter(LocalTime.of(19, 0));

            case DOUBLE_SESSION ->
                // 2 sesi berturut-turut dengan jeda ≤ 10 menit
                hasDoubleSession(todaySessions);

            case CONSISTENCY_HOUR ->
                // Jam mulai sama dengan kemarin (±30 menit)
                hasConsistencyHour(latest, user);

            case REVIEW_STATS ->
                // Harus di-trigger manual via /complete-review
                false;
        };
    }

    /**
     * Estimasi jumlah kejadian distraksi dari total detik.
     * Setiap distraksi minimal 30 detik (durasi away timer).
     */
    private int countDistractionEvents(int distractionSeconds) {
        if (distractionSeconds <= 0) return 0;
        return (int) Math.ceil(distractionSeconds / 30.0);
    }

    private boolean hasDoubleSession(List<StudySession> sessions) {
        if (sessions.size() < 2) return false;
        // Urutkan berdasarkan endTime
        List<StudySession> sorted = sessions.stream()
            .filter(s -> s.getEndTime() != null)
            .sorted(Comparator.comparing(StudySession::getEndTime))
            .collect(Collectors.toList());

        for (int i = 1; i < sorted.size(); i++) {
            LocalDateTime prevEnd = sorted.get(i - 1).getEndTime();
            LocalDateTime currStart = sorted.get(i).getStartTime();
            long gapMinutes = java.time.Duration.between(prevEnd, currStart).toMinutes();
            if (gapMinutes >= 0 && gapMinutes <= 10) {
                return true;
            }
        }
        return false;
    }

    private boolean hasConsistencyHour(StudySession latest, User user) {
        LocalDate yesterday = LocalDate.now().minusDays(1);
        LocalDateTime startOfYesterday = yesterday.atStartOfDay();
        LocalDateTime endOfYesterday = yesterday.plusDays(1).atStartOfDay();

        List<StudySession> yesterdaySessions = studySessionRepository
            .findByUserAndStartTimeBetweenOrderByStartTimeAsc(user, startOfYesterday, endOfYesterday);

        if (yesterdaySessions.isEmpty()) return false;

        // Ambil jam sesi pertama kemarin
        LocalTime yesterdayFirstStart = yesterdaySessions.get(0).getStartTime().toLocalTime();
        LocalTime todayStart = latest.getStartTime().toLocalTime();

        long diffMinutes = Math.abs(
            java.time.Duration.between(yesterdayFirstStart, todayStart).toMinutes()
        );
        return diffMinutes <= 30;
    }

    // ──────────────────────────────────────────────
    //  Helpers
    // ──────────────────────────────────────────────

    private List<DailyQuest> generateDailyQuests(User user, LocalDate date) {
        List<QuestKey> pool = new ArrayList<>(Arrays.asList(QuestKey.values()));
        Collections.shuffle(pool, new Random(user.getId() * 31L + date.toEpochDay()));
        List<QuestKey> selected = pool.subList(0, 3);

        List<DailyQuest> created = new ArrayList<>();
        for (QuestKey key : selected) {
            QuestMeta meta = QUEST_META.get(key);
            DailyQuest q = DailyQuest.builder()
                .user(user)
                .questDate(date)
                .questKey(key)
                .xpReward(meta.xp())
                .completed(false)
                .build();
            created.add(dailyQuestRepository.save(q));
        }
        return created;
    }

    private List<StudySession> getTodaySessions(User user, LocalDate today) {
        return studySessionRepository.findByUserAndStartTimeBetweenOrderByStartTimeAsc(
            user,
            today.atStartOfDay(),
            today.plusDays(1).atStartOfDay()
        );
    }

    private void addXp(User user, int xp) {
        UserXp userXp = userXpRepository.findByUser(user)
            .orElse(UserXp.builder().user(user).totalXp(0).build());
        userXp.setTotalXp(userXp.getTotalXp() + xp);
        userXpRepository.save(userXp);
    }

    private User getUser(String email) {
        return userRepository.findByEmail(email)
            .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
    }

    private DailyQuestResponse buildResponse(LocalDate date, List<DailyQuest> quests) {
        List<DailyQuestResponse.QuestItem> items = quests.stream()
            .map(q -> {
                QuestMeta meta = QUEST_META.get(q.getQuestKey());
                return DailyQuestResponse.QuestItem.builder()
                    .id(q.getId())
                    .questKey(q.getQuestKey())
                    .title(meta.title())
                    .description(meta.description())
                    .xpReward(q.getXpReward())
                    .completed(q.isCompleted())
                    .build();
            })
            .collect(Collectors.toList());

        // XP yang sudah dikumpul hari ini dari quest yang completed
        int todayXp = quests.stream()
            .filter(DailyQuest::isCompleted)
            .mapToInt(DailyQuest::getXpReward)
            .sum();

        // Max XP = total semua xpReward dari 3 quest hari ini
        int maxXp = quests.stream()
            .mapToInt(DailyQuest::getXpReward)
            .sum();

        return DailyQuestResponse.builder()
            .questDate(date.toString())
            .todayXp(todayXp)
            .maxXp(maxXp)
            .quests(items)
            .build();
    }
}