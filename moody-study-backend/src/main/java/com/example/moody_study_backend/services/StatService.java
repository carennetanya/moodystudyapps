package com.example.moody_study_backend.services;

import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StatService {

    private final StudySessionRepository studySessionRepository;
    private final UserRepository userRepository;

    public Map<String, Object> getStats(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        List<StudySession> allSessions = studySessionRepository
                .findByUserOrderByStartTimeDesc(user);

        // ── Data 7 hari terakhir ──────────────────────────────────────
        LocalDateTime sevenDaysAgo = LocalDate.now().minusDays(6).atStartOfDay();
        LocalDateTime endOfToday = LocalDate.now().plusDays(1).atStartOfDay();

        List<StudySession> last7DaysSessions = studySessionRepository
                .findByUserAndStartTimeBetweenOrderByStartTimeAsc(user, sevenDaysAgo, endOfToday);

        // ── Statistik keseluruhan ─────────────────────────────────────
        int totalSessions = allSessions.size();

        int totalMinutes = allSessions.stream()
                .mapToInt(StudySession::getDurationMinutes).sum();

        int totalFocusSeconds = allSessions.stream()
                .mapToInt(StudySession::getFocusSeconds).sum();

        int totalDistractionSeconds = allSessions.stream()
                .mapToInt(StudySession::getDistractionSeconds).sum();

        double avgDurationMinutes = totalSessions == 0 ? 0 :
                Math.round((double) totalMinutes / totalSessions * 10.0) / 10.0;

        // Focus rate: persentase waktu fokus dari total (fokus + distraksi)
        int totalTrackedSeconds = totalFocusSeconds + totalDistractionSeconds;
        double focusRate = totalTrackedSeconds == 0 ? 0 :
                Math.round((double) totalFocusSeconds / totalTrackedSeconds * 1000.0) / 10.0;

        // Mood paling sering
        String favoriteMood = allSessions.stream()
                .filter(s -> s.getMood() != null && !s.getMood().isBlank())
                .collect(Collectors.groupingBy(StudySession::getMood, Collectors.counting()))
                .entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse("none");

        // Lokasi paling sering
        String favoriteLocation = allSessions.stream()
                .filter(s -> s.getLocation() != null && !s.getLocation().isBlank())
                .collect(Collectors.groupingBy(StudySession::getLocation, Collectors.counting()))
                .entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse("none");

        // ── Sesi per hari (7 hari terakhir) untuk grafik ─────────────
        DateTimeFormatter dayFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");

        // Siapkan map dengan semua 7 hari (default 0)
        Map<String, Integer> sessionsPerDay = new LinkedHashMap<>();
        Map<String, Integer> minutesPerDay = new LinkedHashMap<>();
        for (int i = 6; i >= 0; i--) {
            String day = LocalDate.now().minusDays(i).format(dayFormatter);
            sessionsPerDay.put(day, 0);
            minutesPerDay.put(day, 0);
        }

        // Isi dengan data aktual
        for (StudySession s : last7DaysSessions) {
            String day = s.getStartTime().toLocalDate().format(dayFormatter);
            sessionsPerDay.computeIfPresent(day, (k, v) -> v + 1);
            minutesPerDay.computeIfPresent(day, (k, v) -> v + s.getDurationMinutes());
        }

        // ── Distribusi mood (semua sesi) ─────────────────────────────
        Map<String, Long> moodDistribution = allSessions.stream()
                .filter(s -> s.getMood() != null && !s.getMood().isBlank())
                .collect(Collectors.groupingBy(StudySession::getMood, Collectors.counting()));

        // ── Distribusi lokasi (semua sesi) ───────────────────────────
        Map<String, Long> locationDistribution = allSessions.stream()
                .filter(s -> s.getLocation() != null && !s.getLocation().isBlank())
                .collect(Collectors.groupingBy(StudySession::getLocation, Collectors.counting()));

        // ── Sesi minggu ini vs minggu lalu ───────────────────────────
        LocalDateTime startOfThisWeek = LocalDate.now().minusDays(6).atStartOfDay();
        LocalDateTime startOfLastWeek = LocalDate.now().minusDays(13).atStartOfDay();
        LocalDateTime endOfLastWeek = LocalDate.now().minusDays(7).atStartOfDay();

        long sessionsThisWeek = studySessionRepository
                .countByUserAndStartTimeBetween(user, startOfThisWeek, endOfToday);
        long sessionsLastWeek = studySessionRepository
                .countByUserAndStartTimeBetween(user, startOfLastWeek, endOfLastWeek);

        // ── Rakitan response ──────────────────────────────────────────
        Map<String, Object> result = new LinkedHashMap<>();

        // Overall
        result.put("totalSessions", totalSessions);
        result.put("totalStudyMinutes", totalMinutes);
        result.put("totalFocusSeconds", totalFocusSeconds);
        result.put("totalDistractionSeconds", totalDistractionSeconds);
        result.put("avgDurationMinutes", avgDurationMinutes);
        result.put("focusRatePercent", focusRate);

        // Favorit
        result.put("favoriteMood", favoriteMood);
        result.put("favoriteLocation", favoriteLocation);

        // Distribusi
        result.put("moodDistribution", moodDistribution);
        result.put("locationDistribution", locationDistribution);

        // Grafik 7 hari
        result.put("sessionsPerDay", sessionsPerDay);
        result.put("minutesPerDay", minutesPerDay);

        // Perbandingan minggu
        result.put("sessionsThisWeek", sessionsThisWeek);
        result.put("sessionsLastWeek", sessionsLastWeek);

        return result;
    }
}