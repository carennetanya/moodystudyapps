package com.example.moody_study_backend.services;

import com.example.moody_study_backend.dto.AutoScheduleRequest;
import com.example.moody_study_backend.dto.ScheduleResponse;
import com.example.moody_study_backend.entity.Schedule;
import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.ScheduleRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
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
     * @return list jadwal baru yang disimpan ke DB
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

        // Ambil jadwal yang sudah ada (seminggu ke depan) untuk hindari konflik
        List<Schedule> existingSchedules = scheduleRepository
                .findByUserOrderByStudyDateAscStartTimeAsc(user);

        // Serialisasi ke JSON ringkas untuk dikirim ke Gemini
        String sessionJson  = serializeSessions(sessions);
        String scheduleJson = serializeSchedules(existingSchedules);

        int daysAhead = request.getDaysAhead() > 0 ? request.getDaysAhead() : 7;

        // Minta Gemini buat jadwal
        String aiResponse = geminiService.generateAutoSchedule(sessionJson, scheduleJson, daysAhead);

        // Parse response JSON dari Gemini
        List<Map<String, String>> suggestions = parseAiSchedule(aiResponse);

        // Simpan semua saran ke DB
        List<Schedule> saved = new ArrayList<>();
        for (Map<String, String> s : suggestions) {
            try {
                Schedule schedule = Schedule.builder()
                        .user(user)
                        .subject(s.getOrDefault("subject", "Sesi Belajar"))
                        .studyDate(LocalDate.parse(s.get("studyDate")))
                        .startTime(LocalTime.parse(s.get("startTime")))
                        .endTime(LocalTime.parse(s.get("endTime")))
                        .mood(s.getOrDefault("mood", "semangat"))
                        .location(s.getOrDefault("location", "rumah"))
                        .isCompleted(false)
                        .build();

                saved.add(scheduleRepository.save(schedule));
            } catch (Exception e) {
                // Skip entri yang tidak valid daripada gagal total
            }
        }

        if (saved.isEmpty()) {
            throw new RuntimeException(
                    "AI tidak bisa menghasilkan jadwal. Coba lagi atau tambah histori sesi belajar.");
        }

        return saved.stream().map(this::toResponse).collect(Collectors.toList());
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
        } catch (Exception e) {
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
        } catch (Exception e) {
            return "[]";
        }
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, String>> parseAiSchedule(String json) {
        try {
            // Bersihkan markdown code block jika ada
            String cleaned = json.trim()
                    .replaceAll("(?s)```json\\s*", "")
                    .replaceAll("(?s)```\\s*", "")
                    .trim();

            return objectMapper.readValue(cleaned,
                    new TypeReference<List<Map<String, String>>>() {});
        } catch (Exception e) {
            throw new RuntimeException("Gagal memparse jadwal dari AI: " + e.getMessage());
        }
    }

    private ScheduleResponse toResponse(Schedule s) {
        return new ScheduleResponse(
                s.getId(),
                s.getSubject(),
                s.getStudyDate().toString(),
                s.getStartTime().toString(),
                s.getEndTime().toString(),
                s.getLocation(),
                s.getMood(),
                s.isCompleted()
        );
    }
}
