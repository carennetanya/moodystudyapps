package com.example.moody_study_backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RenameFileRequest {
    @NotBlank
    private String newFileName;
}