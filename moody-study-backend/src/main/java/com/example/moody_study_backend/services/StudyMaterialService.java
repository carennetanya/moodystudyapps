package com.example.moody_study_backend.services;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.example.moody_study_backend.dto.MaterialRequest;
import com.example.moody_study_backend.dto.MaterialResponse;
import com.example.moody_study_backend.entity.StudyMaterial;
import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.StudyMaterialRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class StudyMaterialService {

    private final StudyMaterialRepository studyMaterialRepository;
    private final UserRepository userRepository;
    private final StudySessionRepository studySessionRepository;
    private final GeminiService geminiService;

    public MaterialResponse uploadMaterial(String email, MaterialRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        // Ringkasan menggunakan Gemini AI
        String summary = geminiService.summarizeMaterial(request.getOriginalText(), request.getFileName());

        // Link ke sesi jika sessionId dikirim
        StudySession session = null;
        if (request.getSessionId() != null) {
            session = studySessionRepository.findById(request.getSessionId())
                    .orElse(null); // tidak throw — kalau tidak ketemu tetap lanjut tanpa link
        }

        StudyMaterial material = StudyMaterial.builder()
                .user(user)
                .studySession(session)
                .fileName(request.getFileName())
                .originalText(request.getOriginalText())
                .summary(summary)
                .uploadedAt(LocalDateTime.now())
                .build();

        studyMaterialRepository.save(material);

        return toResponse(material);
    }

    public List<MaterialResponse> getMaterials(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        return studyMaterialRepository.findByUserOrderByUploadedAtDesc(user)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public MaterialResponse getMaterialById(Long id) {
        StudyMaterial material = studyMaterialRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Materi tidak ditemukan"));

        return toResponse(material);
    }

    private MaterialResponse toResponse(StudyMaterial m) {
        return new MaterialResponse(
                m.getId(),
                m.getFileName(),
                m.getSummary(),
                m.getUploadedAt().toString()
        );
    }
}