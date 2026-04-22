package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.services.StatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/stats")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StatController {

    private final StatService statService;

    @GetMapping
    public ResponseEntity<Map<String, Object>> getStats(Authentication authentication) {
        return ResponseEntity.ok(statService.getStats(authentication.getName()));
    }
}