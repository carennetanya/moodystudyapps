package com.example.moody_study_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class SavedFileResponse {
    private Long id;
    private String fileName;
    private String fileType;
    private String content;
    private String savedAt;
}