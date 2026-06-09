package com.example.moody_study_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class MeResponse {
    private String email;
    private String username;
    private String name;
}
