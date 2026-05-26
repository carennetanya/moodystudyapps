package com.example.moody_study_backend.services;

import com.example.moody_study_backend.dto.AutoScheduleRequest;
import com.example.moody_study_backend.dto.ScheduleResponse;
import com.example.moody_study_backend.entity.Schedule;
import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.ScheduleRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AutoScheduleService {

    private final ScheduleRepository scheduleRepository;
    private final StudySessionRepository studySessionRepository;
    private final UserRepository userRepository;
    private final GeminiService geminiService;
    private final ObjectMapper objectMapper;

    /**
     * Generate jadwal belajar otomatis berbasis AI.
     * AI menganalisa histori sesi & jadwal existing lalu menyarankan slot optimal.
     *
     * @return list jadwal AI sebagai suggestion tanpa menyimpan otomatis ke DB
     */
    public List<ScheduleResponse> generateAutoSchedule(String email, AutoScheduleRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        // Ambil histori sesi belajar (max 20 sesi terakhir sebagai konteks)
        List<StudySession> sessions = studySessionRepository
                .findByUserOrderByStartTimeDesc(user)
                .stream()
                .limit(20)
                .collect(Collectors.toList());

        // Ambil jadwal yang sudah ada untuk hindari konflik
        List<Schedule> existingSchedules = scheduleRepository
                .findByUserOrderByStudyDateAscStartTimeAsc(user);

        // Serialisasi ke JSON ringkas untuk dikirim ke Gemini
        String sessionJson = serializeSessions(sessions);
        String scheduleJson = serializeSchedules(existingSchedules);

        int daysAhead = request.getDaysAhead() > 0 ? request.getDaysAhead() : 7;

        String subjectsText = request.getSubjects().isEmpty()
                ? "Mata pelajaran: semua pelajaran sesuai histori dan prioritas belajar."
                : "Mata pelajaran: " + String.join(", ", request.getSubjects());
        String daysText = request.getAvailableDays().isEmpty()
                ? "Hari tersedia: Senin, Selasa, Rabu, Kamis, Jumat, Sabtu, Minggu"
                : "Hari tersedia: " + String.join(", ", request.getAvailableDays());
        String timeText = "Jam belajar: " + request.getStartHour() + " sampai " + request.getEndHour();
        String durationText = "Durasi per sesi: " + request.getDurationMinutes() + " menit.";

        String extraInstructions = subjectsText + "\n" + daysText + "\n" + timeText + "\n" + durationText;

        // Minta Gemini buat jadwal
        String aiResponse = geminiService.generateAutoSchedule(sessionJson, scheduleJson, daysAhead, extraInstructions);

        // Parse response JSON dari Gemini
        List<Map<String, String>> suggestions = parseAiSchedule(aiResponse);

        if (suggestions.isEmpty()) {
            throw new RuntimeException(
                    "AI tidak bisa menghasilkan jadwal. Coba lagi atau tambah histori sesi belajar.");
        }

        return suggestions.stream()
                .map(s -> new ScheduleResponse(
                        0L,
                        s.getOrDefault("subject", "Sesi Belajar"),
                        s.getOrDefault("studyDate", ""),
                        s.getOrDefault("startTime", ""),
                        s.getOrDefault("endTime", ""),
                        s.getOrDefault("location", ""),
                        s.getOrDefault("mood", ""),
                        false
                ))
                .collect(Collectors.toList());
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    private String serializeSessions(List<StudySession> sessions) {
        try {
            List<Map<String, Object>> list = sessions.stream().map(s -> Map.<String, Object>of(
                    "mood",                s.getMood(),
                    "location",            s.getLocation(),
                    "durationMinutes",     s.getDurationMinutes(),
                    "focusSeconds",        s.getFocusSeconds(),
                    "distractionSeconds",  s.getDistractionSeconds(),
                    "startTime",           s.getStartTime() != null ? s.getStartTime().toString() : ""
            )).collect(Collectors.toList());
            return objectMapper.writeValueAsString(list);
        } catch (JsonProcessingException e) {
            return "[]";
        }
    }

    private String serializeSchedules(List<Schedule> schedules) {
        try {
            List<Map<String, Object>> list = schedules.stream().map(s -> Map.<String, Object>of(
                    "subject",    s.getSubject(),
                    "studyDate",  s.getStudyDate().toString(),
                    "startTime",  s.getStartTime().toString(),
                    "endTime",    s.getEndTime().toString(),
                    "mood",       s.getMood() != null ? s.getMood() : "",
                    "location",   s.getLocation() != null ? s.getLocation() : ""
            )).collect(Collectors.toList());
            return objectMapper.writeValueAsString(list);
        } catch (JsonProcessingException e) {
            return "[]";
        }
    }

    private List<Map<String, String>> parseAiSchedule(String json) {
        try {
            // Bersihkan markdown code block jika ada
            String cleaned = json.trim()
                    .replaceAll("(?s)```json\\s*", "")
                    .replaceAll("(?s)```\\s*", "")
                    .trim();

            return objectMapper.readValue(cleaned,
                    new TypeReference<List<Map<String, String>>>() {});
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Gagal memparse jadwal dari AI: " + e.getMessage());
        }
    }
}
