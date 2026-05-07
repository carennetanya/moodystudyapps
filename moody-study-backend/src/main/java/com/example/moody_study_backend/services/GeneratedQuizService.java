package com.example.moody_study_backend.services;

import com.example.moody_study_backend.dto.GenerateQuizRequest;
import com.example.moody_study_backend.dto.GeneratedQuizResponse;
import com.example.moody_study_backend.entity.GeneratedQuiz;
import com.example.moody_study_backend.entity.StudyMaterial;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.GeneratedQuizRepository;
import com.example.moody_study_backend.repository.StudyMaterialRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GeneratedQuizService {

    private final GeneratedQuizRepository generatedQuizRepository;
    private final StudyMaterialRepository studyMaterialRepository;
    private final UserRepository userRepository;
    private final GeminiService geminiService;

    /**
     * Generate soal latihan dari materi. Mengecek sisa jatah generate dari streak.
     */
    public GeneratedQuizResponse generateQuiz(String email, GenerateQuizRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        StudyMaterial material = studyMaterialRepository.findById(request.getMaterialId())
                .orElseThrow(() -> new RuntimeException("Materi tidak ditemukan"));

        // Pastikan materi milik user yang sama
        if (!material.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Kamu tidak berhak mengakses materi ini");
        }

        // Generate soal via Gemini
        String quizContent = geminiService.generateQuiz(
                material.getOriginalText(),
                request.getQuizType(),
                request.getDifficulty(),
                request.getQuestionCount()
        );

        GeneratedQuiz quiz = GeneratedQuiz.builder()
                .user(user)
                .material(material)
                .quizContent(quizContent)
                .generatedAt(LocalDateTime.now())
                .build();

        generatedQuizRepository.save(quiz);

        return toResponse(quiz);
    }

    /**
     * Ambil semua soal yang pernah di-generate oleh user.
     */
    public List<GeneratedQuizResponse> getQuizzes(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        return generatedQuizRepository.findByUserOrderByGeneratedAtDesc(user)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Ambil satu quiz berdasarkan ID.
     */
    public GeneratedQuizResponse getQuizById(Long id) {
        GeneratedQuiz quiz = generatedQuizRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Quiz tidak ditemukan"));
        return toResponse(quiz);
    }

    /**
     * Hapus quiz.
     */
    public void deleteQuiz(Long id) {
        if (!generatedQuizRepository.existsById(id)) {
            throw new RuntimeException("Quiz tidak ditemukan");
        }
        generatedQuizRepository.deleteById(id);
    }

    // -----------------------------------------------------------------------

    private GeneratedQuizResponse toResponse(GeneratedQuiz q) {
        return new GeneratedQuizResponse(
                q.getId(),
                q.getMaterial().getId(),
                q.getMaterial().getFileName(),
                q.getQuizContent(),
                q.getGeneratedAt().toString()
        );
    }
}