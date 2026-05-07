package com.example.moody_study_backend.dto;

import lombok.Data;

@Data
public class AutoScheduleRequest {

    // Berapa hari ke depan yang mau dijadwalkan (default 7)
    private int daysAhead = 7;
}
