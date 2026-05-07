package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.dto.GenerateQuizRequest;
import com.example.moody_study_backend.dto.GeneratedQuizResponse;
import com.example.moody_study_backend.services.GeneratedQuizService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/quiz")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class GeneratedQuizController {

    private final GeneratedQuizService generatedQuizService;

    /**
     * POST /api/quiz/generate
     * Generate soal baru dari materi. Membutuhkan jatah generate (streak).
     */
    @PostMapping("/generate")
    public ResponseEntity<GeneratedQuizResponse> generateQuiz(
            @Valid @RequestBody GenerateQuizRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(
                generatedQuizService.generateQuiz(authentication.getName(), request)
        );
    }

    /**
     * GET /api/quiz
     * Ambil semua quiz milik user.
     */
    @GetMapping
    public ResponseEntity<List<GeneratedQuizResponse>> getQuizzes(Authentication authentication) {
        return ResponseEntity.ok(
                generatedQuizService.getQuizzes(authentication.getName())
        );
    }

    /**
     * GET /api/quiz/{id}
     * Ambil quiz berdasarkan ID.
     */
    @GetMapping("/{id}")
    public ResponseEntity<GeneratedQuizResponse> getQuizById(@PathVariable Long id) {
        return ResponseEntity.ok(generatedQuizService.getQuizById(id));
    }

    /**
     * DELETE /api/quiz/{id}
     * Hapus quiz.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteQuiz(@PathVariable Long id) {
        generatedQuizService.deleteQuiz(id);
        return ResponseEntity.noContent().build();
    }
}
