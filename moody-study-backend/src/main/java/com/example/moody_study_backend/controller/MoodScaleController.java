package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.entity.MoodScale;
import com.example.moody_study_backend.services.MoodScaleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/mood-scale")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class MoodScaleController {

    private final MoodScaleService moodScaleService;

    @PostMapping("/record")
    public ResponseEntity<MoodScale> recordMood(
            @RequestBody Map<String, Object> request,
            Authentication authentication) {
        String moodType = (String) request.get("moodType");
        int moodValue = ((Number) request.get("moodValue")).intValue();
        String moodFeel = (String) request.get("moodFeel");
        int moodIntensity = ((Number) request.getOrDefault("moodIntensity", 0)).intValue();
        String moodNote = (String) request.get("moodNote");
        
        MoodScale mood = moodScaleService.recordMood(authentication.getName(), moodType, 
                                                      moodValue, moodFeel, moodIntensity, moodNote);
        return ResponseEntity.ok(mood);
    }

    @GetMapping
    public ResponseEntity<List<MoodScale>> getUserMoods(Authentication authentication) {
        List<MoodScale> moods = moodScaleService.getUserMoods(authentication.getName());
        return ResponseEntity.ok(moods);
    }

    @GetMapping("/date-range")
    public ResponseEntity<List<MoodScale>> getMoodsByDateRange(
            @RequestParam String startDate,
            @RequestParam String endDate,
            Authentication authentication) {
        LocalDateTime start = LocalDateTime.parse(startDate);
        LocalDateTime end = LocalDateTime.parse(endDate);
        List<MoodScale> moods = moodScaleService.getMoodsByDateRange(authentication.getName(), start, end);
        return ResponseEntity.ok(moods);
    }

    @GetMapping("/type/{moodType}")
    public ResponseEntity<List<MoodScale>> getMoodsByType(
            @PathVariable String moodType,
            Authentication authentication) {
        List<MoodScale> moods = moodScaleService.getMoodsByType(authentication.getName(), moodType);
        return ResponseEntity.ok(moods);
    }
}
