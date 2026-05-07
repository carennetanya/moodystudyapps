package com.example.moody_study_backend.services;

import com.example.moody_study_backend.dto.MaterialRequest;
import com.example.moody_study_backend.dto.MaterialResponse;
import com.example.moody_study_backend.entity.StudyMaterial;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.StudyMaterialRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StudyMaterialService {

    private final StudyMaterialRepository studyMaterialRepository;
    private final UserRepository userRepository;
    private final GeminiService geminiService;

    public MaterialResponse uploadMaterial(String email, MaterialRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        // Ringkasan menggunakan Gemini AI
        String summary = geminiService.summarizeMaterial(request.getOriginalText());

        StudyMaterial material = StudyMaterial.builder()
                .user(user)
                .fileName(request.getFileName())
                .originalText(request.getOriginalText())
                .summary(summary)
                .uploadedAt(LocalDateTime.now())
                .build();

        studyMaterialRepository.save(material);

        return new MaterialResponse(
                material.getId(),
                material.getFileName(),
                material.getSummary(),
                material.getUploadedAt().toString()
        );
    }

    public List<MaterialResponse> getMaterials(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        return studyMaterialRepository.findByUserOrderByUploadedAtDesc(user)
                .stream()
                .map(m -> new MaterialResponse(
                        m.getId(),
                        m.getFileName(),
                        m.getSummary(),
                        m.getUploadedAt().toString()
                ))
                .collect(Collectors.toList());
    }

    public MaterialResponse getMaterialById(Long id) {
        StudyMaterial material = studyMaterialRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Materi tidak ditemukan"));

        return new MaterialResponse(
                material.getId(),
                material.getFileName(),
                material.getSummary(),
                material.getUploadedAt().toString()
        );
    }
}
