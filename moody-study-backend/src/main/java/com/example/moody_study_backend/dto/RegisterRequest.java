package com.example.moody_study_backend.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class RegisterRequest {

    @NotBlank(message = "validation.username.blank")
    @Size(min = 3, message = "validation.username.tooShort")
    @Size(max = 16, message = "validation.username.tooLong")
    @Pattern(regexp = "^[a-z0-9._-]+$", message = "validation.username.pattern")
    private String username;

    @NotBlank(message = "validation.name.blank")
    @Size(max = 30, message = "validation.name.tooLong")
    private String name;

    @NotBlank(message = "validation.email.blank")
    @Email(message = "validation.email.invalid")
    private String email;

    @NotBlank(message = "validation.password.blank")
    @Size(min = 6, message = "validation.password.tooShort")
    private String password;
}
