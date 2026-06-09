package com.example.moody_study_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateNameRequest {

    @NotBlank(message = "validation.name.blank")
    @Size(max = 30, message = "validation.name.tooLong")
    private String name;
}
