package com.example.moody_study_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class MaterialResponse {
    private Long id;
    private String fileName;
    private String summary;
    private String uploadedAt;
}