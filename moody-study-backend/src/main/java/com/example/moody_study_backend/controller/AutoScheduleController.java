package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.dto.AutoScheduleRequest;
import com.example.moody_study_backend.dto.ScheduleResponse;
import com.example.moody_study_backend.services.AutoScheduleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/schedule/auto")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AutoScheduleController {

    private final AutoScheduleService autoScheduleService;

    /**
     * POST /api/schedule/auto
     * Generate jadwal belajar otomatis berbasis AI.
     * AI menganalisa histori sesi & jadwal existing lalu menyarankan slot optimal.
     *
     * Body (opsional):
     * {
     *   "daysAhead": 7
     * }
     */
    @PostMapping
    public ResponseEntity<List<ScheduleResponse>> generateAutoSchedule(
            @RequestBody(required = false) AutoScheduleRequest request,
            Authentication authentication) {

        if (request == null) {
            request = new AutoScheduleRequest(); // pakai default 7 hari
        }

        return ResponseEntity.ok(
                autoScheduleService.generateAutoSchedule(authentication.getName(), request)
        );
    }
}
