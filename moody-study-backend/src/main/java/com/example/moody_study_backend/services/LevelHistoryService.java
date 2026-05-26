package com.example.moody_study_backend.services;

import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.example.moody_study_backend.dto.LevelHistoryResponse;
import com.example.moody_study_backend.entity.StudyMaterial;
import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.AwardLevelUpRepository;
import com.example.moody_study_backend.repository.StudyMaterialRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class LevelHistoryService {

    private final UserRepository userRepository;
    private final StudySessionRepository studySessionRepository;
    private final StudyMaterialRepository studyMaterialRepository;
    private final AwardLevelUpRepository awardLevelUpRepository;

    private static final int[] LEVEL_START = {1, 6, 13, 22, 33};
    private static final int[] LEVEL_END   = {5, 12, 21, 32, Integer.MAX_VALUE};
    private static final int[] XP_REWARDS  = {0, 50, 100, 200, 400};
    private static final String[] LEVEL_NAMES = {"Beginner", "Learner", "Practitioner", "Expert", "Master"};
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    public LevelHistoryResponse getLevelHistory(String email, int level) {
        if (level < 1 || level > 5) throw new RuntimeException("Level tidak valid");

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        int idx = level - 1;
        int fromIndex = LEVEL_START[idx] - 1;
        int toIndex   = LEVEL_END[idx];

        // Ambil semua sesi urut dari awal
        List<StudySession> allSessions = studySessionRepository.findByUserOrderByStartTimeAsc(user);

        List<StudySession> levelSessions = fromIndex >= allSessions.size()
                ? List.of()
                : allSessions.subList(fromIndex, Math.min(toIndex, allSessions.size()));

        int totalMinutes = levelSessions.stream().mapToInt(StudySession::getDurationMinutes).sum();

        String startedAt = levelSessions.isEmpty() ? null
                : levelSessions.get(0).getStartTime().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));

        String completedAt = awardLevelUpRepository.findByUserAndLevel(user, level)
                .map(a -> a.getAwardedAt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd")))
                .orElse(null);

        // Build session items dengan file-nya masing-masing
        List<LevelHistoryResponse.SessionItem> sessionItems = levelSessions.stream()
                .map(s -> {
                    // Ambil file yang diupload dalam sesi ini
                    List<StudyMaterial> materials = studyMaterialRepository.findByStudySession(s);
                    List<LevelHistoryResponse.FileItem> files = materials.stream()
                            .map(m -> LevelHistoryResponse.FileItem.builder()
                                    .id(m.getId())
                                    .fileName(m.getFileName())
                                    .uploadedAt(m.getUploadedAt().format(FMT))
                                    .build())
                            .collect(Collectors.toList());

                    return LevelHistoryResponse.SessionItem.builder()
                            .id(s.getId())
                            .startTime(s.getStartTime().format(FMT))
                            .durationMinutes(s.getDurationMinutes())
                            .distractionSeconds(s.getDistractionSeconds())
                            .mood(s.getMood())
                            .location(s.getLocation())
                            .files(files)
                            .build();
                })
                .collect(Collectors.toList());

        return LevelHistoryResponse.builder()
                .level(level)
                .levelName(LEVEL_NAMES[idx])
                .totalSessions(levelSessions.size())
                .totalMinutes(totalMinutes)
                .xpBonus(XP_REWARDS[idx])
                .startedAt(startedAt)
                .completedAt(completedAt)
                .sessions(sessionItems)
                .build();
    }
}