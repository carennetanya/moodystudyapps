package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.dto.ScheduleRequest;
import com.example.moody_study_backend.dto.ScheduleResponse;
import com.example.moody_study_backend.services.ScheduleService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/schedule")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ScheduleController {

    private final ScheduleService scheduleService;

    @PostMapping
    public ResponseEntity<ScheduleResponse> createSchedule(
            @Valid @RequestBody ScheduleRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(
                scheduleService.createSchedule(authentication.getName(), request)
        );
    }

    @GetMapping
    public ResponseEntity<List<ScheduleResponse>> getSchedules(Authentication authentication) {
        return ResponseEntity.ok(
                scheduleService.getSchedules(authentication.getName())
        );
    }

    @PatchMapping("/{id}/complete")
    public ResponseEntity<ScheduleResponse> completeSchedule(@PathVariable Long id) {
        return ResponseEntity.ok(scheduleService.completeSchedule(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSchedule(@PathVariable Long id) {
        scheduleService.deleteSchedule(id);
        return ResponseEntity.noContent().build();
    }
}