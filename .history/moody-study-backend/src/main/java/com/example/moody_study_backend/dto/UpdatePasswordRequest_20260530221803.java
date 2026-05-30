package com.example.moody_study_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdatePasswordRequest {
    @NotBlank
    private String currentPassword;

    @NotBlank
    @Size(min = 6, message = "Password harus minimal 6 karakter")
    private String newPassword;

    @NotBlank
    private String confirmPassword;
}
