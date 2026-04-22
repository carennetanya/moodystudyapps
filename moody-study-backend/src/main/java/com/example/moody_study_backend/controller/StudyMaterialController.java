package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.dto.MaterialRequest;
import com.example.moody_study_backend.dto.MaterialResponse;
import com.example.moody_study_backend.services.StudyMaterialService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/material")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class StudyMaterialController {

    private final StudyMaterialService studyMaterialService;

    @PostMapping("/upload")
    public ResponseEntity<MaterialResponse> upload(
            @Valid @RequestBody MaterialRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(
                studyMaterialService.uploadMaterial(authentication.getName(), request)
        );
    }

    @GetMapping
    public ResponseEntity<List<MaterialResponse>> getMaterials(Authentication authentication) {
        return ResponseEntity.ok(
                studyMaterialService.getMaterials(authentication.getName())
        );
    }

    @GetMapping("/{id}")
    public ResponseEntity<MaterialResponse> getMaterialById(@PathVariable Long id) {
        return ResponseEntity.ok(studyMaterialService.getMaterialById(id));
    }
}