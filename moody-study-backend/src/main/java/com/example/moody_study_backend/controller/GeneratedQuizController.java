package com.example.moody_study_backend.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.moody_study_backend.dto.GenerateQuizRequest;
import com.example.moody_study_backend.dto.GeneratedQuizResponse;
import com.example.moody_study_backend.services.GeneratedQuizService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/quiz")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class GeneratedQuizController {

    private final GeneratedQuizService generatedQuizService;

    @PostMapping("/generate")
    public ResponseEntity<GeneratedQuizResponse> generateQuiz(
            @Valid @RequestBody GenerateQuizRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(
                generatedQuizService.generateQuiz(authentication.getName(), request));
    }

    @GetMapping
    public ResponseEntity<List<GeneratedQuizResponse>> getQuizzes(Authentication authentication) {
        return ResponseEntity.ok(generatedQuizService.getQuizzes(authentication.getName()));
    }

    /** GET /api/quiz/saved — hanya quiz yang sudah disimpan (untuk tab Kuis) */
    @GetMapping("/saved")
    public ResponseEntity<List<GeneratedQuizResponse>> getSavedQuizzes(Authentication authentication) {
        return ResponseEntity.ok(generatedQuizService.getSavedQuizzes(authentication.getName()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<GeneratedQuizResponse> getQuizById(@PathVariable Long id) {
        return ResponseEntity.ok(generatedQuizService.getQuizById(id));
    }

    /** POST /api/quiz/{id}/save — toggle save/unsave */
    @PostMapping("/{id}/save")
    public ResponseEntity<GeneratedQuizResponse> toggleSave(
            @PathVariable Long id,
            Authentication authentication) {
        return ResponseEntity.ok(generatedQuizService.toggleSave(authentication.getName(), id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteQuiz(@PathVariable Long id) {
        generatedQuizService.deleteQuiz(id);
        return ResponseEntity.noContent().build();
    }
}