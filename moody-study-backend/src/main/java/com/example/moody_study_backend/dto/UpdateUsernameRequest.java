package com.example.moody_study_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateUsernameRequest {

    @NotBlank(message = "validation.username.blank")
    @Size(min = 3, message = "validation.username.tooShort")
    @Size(max = 16, message = "validation.username.tooLong")
    @Pattern(regexp = "^[a-z0-9._-]+$", message = "validation.username.pattern")
    private String username;
}
