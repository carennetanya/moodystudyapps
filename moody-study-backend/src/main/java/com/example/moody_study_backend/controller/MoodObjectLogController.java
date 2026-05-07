package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.entity.MoodObjectLog;
import com.example.moody_study_backend.services.MoodObjectLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/mood-logs")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class MoodObjectLogController {

    private final MoodObjectLogService moodObjectLogService;

    @PostMapping("/create")
    public ResponseEntity<MoodObjectLog> createLog(
            @RequestBody Map<String, Object> request,
            Authentication authentication) {
        String subject = (String) request.get("subject");
        String moodFeel = (String) request.get("moodFeel");
        int moodIntensity = ((Number) request.getOrDefault("moodIntensity", 0)).intValue();
        String notes = (String) request.get("notes");
        
        MoodObjectLog log = moodObjectLogService.createMoodLog(authentication.getName(), subject, 
                                                               moodFeel, moodIntensity, notes);
        return ResponseEntity.ok(log);
    }

    @GetMapping
    public ResponseEntity<List<MoodObjectLog>> getUserLogs(Authentication authentication) {
        List<MoodObjectLog> logs = moodObjectLogService.getUserLogs(authentication.getName());
        return ResponseEntity.ok(logs);
    }

    @GetMapping("/subject/{subject}")
    public ResponseEntity<List<MoodObjectLog>> getLogsBySubject(
            @PathVariable String subject,
            Authentication authentication) {
        List<MoodObjectLog> logs = moodObjectLogService.getLogsBySubject(authentication.getName(), subject);
        return ResponseEntity.ok(logs);
    }

    @GetMapping("/date-range")
    public ResponseEntity<List<MoodObjectLog>> getLogsByDateRange(
            @RequestParam String startDate,
            @RequestParam String endDate,
            Authentication authentication) {
        LocalDateTime start = LocalDateTime.parse(startDate);
        LocalDateTime end = LocalDateTime.parse(endDate);
        List<MoodObjectLog> logs = moodObjectLogService.getLogsByDateRange(authentication.getName(), start, end);
        return ResponseEntity.ok(logs);
    }

    @GetMapping("/{logId}")
    public ResponseEntity<MoodObjectLog> getLog(@PathVariable Long logId) {
        MoodObjectLog log = moodObjectLogService.getMoodLog(logId);
        return ResponseEntity.ok(log);
    }
}
