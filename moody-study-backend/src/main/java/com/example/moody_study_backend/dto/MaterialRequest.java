package com.example.moody_study_backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class MaterialRequest {
    @NotBlank
    private String fileName;

    @NotBlank
    private String originalText;
}