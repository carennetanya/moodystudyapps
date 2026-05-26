package com.example.moody_study_backend.services;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.example.moody_study_backend.dto.GenerateQuizRequest;
import com.example.moody_study_backend.dto.GeneratedQuizResponse;
import com.example.moody_study_backend.entity.GeneratedQuiz;
import com.example.moody_study_backend.entity.StudyMaterial;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.GeneratedQuizRepository;
import com.example.moody_study_backend.repository.StudyMaterialRepository;
import com.example.moody_study_backend.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class GeneratedQuizService {

    private final GeneratedQuizRepository generatedQuizRepository;
    private final StudyMaterialRepository studyMaterialRepository;
    private final UserRepository userRepository;
    private final GeminiService geminiService;

    public GeneratedQuizResponse generateQuiz(String email, GenerateQuizRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        StudyMaterial material = studyMaterialRepository.findById(request.getMaterialId())
                .orElseThrow(() -> new RuntimeException("Materi tidak ditemukan"));

        if (!material.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Kamu tidak berhak mengakses materi ini");
        }

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
                .saved(false)
                .build();

        generatedQuizRepository.save(quiz);
        return toResponse(quiz);
    }

    public List<GeneratedQuizResponse> getQuizzes(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
        return generatedQuizRepository.findByUserOrderByGeneratedAtDesc(user)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    /** Ambil hanya quiz yang sudah disimpan — untuk tab Kuis */
    public List<GeneratedQuizResponse> getSavedQuizzes(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
        return generatedQuizRepository.findByUserAndSavedTrueOrderByGeneratedAtDesc(user)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    public GeneratedQuizResponse getQuizById(Long id) {
        return toResponse(generatedQuizRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Quiz tidak ditemukan")));
    }

    /** Toggle save/unsave flashcard */
    public GeneratedQuizResponse toggleSave(String email, Long quizId) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
        GeneratedQuiz quiz = generatedQuizRepository.findById(quizId)
                .orElseThrow(() -> new RuntimeException("Quiz tidak ditemukan"));
        if (!quiz.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Kamu tidak berhak mengakses quiz ini");
        }
        quiz.setSaved(!quiz.isSaved());
        generatedQuizRepository.save(quiz);
        return toResponse(quiz);
    }

    public void deleteQuiz(Long id) {
        if (!generatedQuizRepository.existsById(id)) {
            throw new RuntimeException("Quiz tidak ditemukan");
        }
        generatedQuizRepository.deleteById(id);
    }

    private GeneratedQuizResponse toResponse(GeneratedQuiz q) {
        return new GeneratedQuizResponse(
                q.getId(),
                q.getMaterial().getId(),
                q.getMaterial().getFileName(),
                q.getQuizContent(),
                q.getGeneratedAt().toString(),
                q.isSaved()
        );
    }
}