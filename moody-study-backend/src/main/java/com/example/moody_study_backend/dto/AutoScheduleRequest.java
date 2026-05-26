package com.example.moody_study_backend.dto;

import java.util.ArrayList;
import java.util.List;

import lombok.Data;

@Data
public class AutoScheduleRequest {

    // Berapa hari ke depan yang mau dijadwalkan (default 7)
    private int daysAhead = 7;

    // Mata pelajaran yang ingin dijadwalkan
    private List<String> subjects = new ArrayList<>();

    // Hari yang tersedia untuk jadwal
    private List<String> availableDays = new ArrayList<>();

    private String startHour = "08:00";
    private String endHour = "22:00";
    private int durationMinutes = 90;
}
