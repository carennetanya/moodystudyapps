package com.example.moody_study_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LevelHistoryResponse {

    private int level;
    private String levelName;
    private int totalSessions;
    private int totalMinutes;
    private int coinBonus;
    private String startedAt;
    private String completedAt;
    private List<SessionItem> sessions;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SessionItem {
        private Long id;
        private String startTime;
        private int durationMinutes;
        private int distractionSeconds;
        private String mood;
        private String location;
        private List<FileItem> files; // file yang diupload dalam sesi ini
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FileItem {
        private Long id;
        private String fileName;
        private String uploadedAt;
    }
}