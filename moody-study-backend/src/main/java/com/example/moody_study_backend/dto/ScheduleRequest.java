package com.example.moody_study_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ScheduleRequest {
    @NotBlank
    private String subject;

    @NotNull
    private String studyDate;

    @NotNull
    private String startTime;

    @NotNull
    private String endTime;

    private String location;
    private String mood;
}