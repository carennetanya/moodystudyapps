package com.example.moody_study_backend.services;

import com.example.moody_study_backend.entity.MoodObjectLog;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.MoodObjectLogRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MoodObjectLogService {

    private final MoodObjectLogRepository moodObjectLogRepository;
    private final UserRepository userRepository;

    public MoodObjectLog createMoodLog(String email, String subject, String moodFeel,
                                        int moodIntensity, String notes) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        MoodObjectLog log = MoodObjectLog.builder()
                .user(user)
                .subject(subject)
                .moodFeel(moodFeel)
                .moodIntensity(moodIntensity)
                .moodDate(LocalDateTime.now())
                .notes(notes)
                .build();

        return moodObjectLogRepository.save(log);
    }

    public List<MoodObjectLog> getUserLogs(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
        return moodObjectLogRepository.findByUser(user);
    }

    public List<MoodObjectLog> getLogsBySubject(String email, String subject) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
        return moodObjectLogRepository.findByUserAndSubject(user, subject);
    }

    public List<MoodObjectLog> getLogsByDateRange(String email, LocalDateTime startDate, LocalDateTime endDate) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
        return moodObjectLogRepository.findByUserAndMoodDateBetween(user, startDate, endDate);
    }

    public MoodObjectLog getMoodLog(Long logId) {
        return moodObjectLogRepository.findById(logId)
                .orElseThrow(() -> new RuntimeException("Mood Log tidak ditemukan"));
    }
}
