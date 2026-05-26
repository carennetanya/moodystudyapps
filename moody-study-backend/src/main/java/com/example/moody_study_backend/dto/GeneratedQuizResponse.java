package com.example.moody_study_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class GeneratedQuizResponse {
    private Long id;
    private Long materialId;
    private String fileName;
    private String quizContent;
    private String generatedAt;
    private boolean saved;
}