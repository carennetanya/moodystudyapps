package com.example.moody_study_backend.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class GenerateQuizRequest {

    @NotNull(message = "Material ID tidak boleh kosong")
    private Long materialId;

    // "multiple_choice" atau "essay"
    private String quizType = "multiple_choice";

    // "easy", "medium", "hard"
    private String difficulty = "medium";

    // Jumlah soal yang diminta (1-10)
    private int questionCount = 5;
}
