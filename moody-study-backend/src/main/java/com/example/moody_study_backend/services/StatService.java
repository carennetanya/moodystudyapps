package com.example.moody_study_backend.services;

import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StatService {

    private final StudySessionRepository studySessionRepository;
    private final UserRepository userRepository;

    public Map<String, Object> getStats(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        List<StudySession> sessions = studySessionRepository
                .findByUserOrderByStartTimeDesc(user);

        int totalSessions = sessions.size();
        int totalFocusSeconds = sessions.stream()
                .mapToInt(StudySession::getFocusSeconds).sum();
        int totalDistractionSeconds = sessions.stream()
                .mapToInt(StudySession::getDistractionSeconds).sum();
        int totalMinutes = sessions.stream()
                .mapToInt(StudySession::getDurationMinutes).sum();

        // Mood paling sering
        String favoriteMood = sessions.stream()
                .collect(Collectors.groupingBy(StudySession::getMood, Collectors.counting()))
                .entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse("none");

        return Map.of(
                "totalSessions", totalSessions,
                "totalStudyMinutes", totalMinutes,
                "totalFocusSeconds", totalFocusSeconds,
                "totalDistractionSeconds", totalDistractionSeconds,
                "favoriteMood", favoriteMood
        );
    }
}