package com.example.moody_study_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class StudySessionRequest {

    @NotBlank
    private String mood;

    @NotBlank
    private String location;

    @NotNull
    private Integer durationMinutes;

    @NotNull
    private Integer focusSeconds;

    @NotNull
    private Integer distractionSeconds;
}