package com.example.moody_study_backend.dto;

import lombok.Data;

@Data
public class UpdateAccountRequest {
    private String newEmail;
    private String newPassword;
    private String currentPassword;
}