package com.example.moody_study_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ScheduleResponse {
    private Long id;
    private String subject;
    private String studyDate;
    private String startTime;
    private String endTime;
    private String location;
    private String mood;
    private boolean isCompleted;
}