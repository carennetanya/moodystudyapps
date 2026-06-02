package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.BaseIntegrationTest;
import com.example.moody_study_backend.dto.LoginRequest;
import com.example.moody_study_backend.dto.RegisterRequest;
import com.example.moody_study_backend.dto.UpdateEmailRequest;
import com.example.moody_study_backend.dto.UpdatePasswordRequest;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

public class AuthControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void register_success() throws Exception {
        RegisterRequest r = new RegisterRequest();
        r.setUsername("newuser");
        r.setName("New User");
        r.setEmail("newuser@example.com");
        r.setPassword("password123");

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(r)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists());
    }

    @Test
    public void register_badRequest_missingFields() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void login_success() throws Exception {
        LoginRequest r = new LoginRequest();
        r.setEmail("test@example.com");
        r.setPassword("password123");

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(r)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists());
    }

    @Test
    public void updateEmail_success() throws Exception {
        UpdateEmailRequest r = new UpdateEmailRequest();
        r.setNewEmail("updated@example.com");
        r.setPassword("password123");

        mockMvc.perform(put("/api/auth/update-email")
                        .with(authenticatedUser())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(r)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("updated@example.com"));
    }

    @Test
    public void updatePassword_success() throws Exception {
        UpdatePasswordRequest r = new UpdatePasswordRequest();
        r.setCurrentPassword("password123");
        r.setNewPassword("newpass123");
        r.setConfirmPassword("newpass123");

        mockMvc.perform(put("/api/auth/update-password")
                        .with(authenticatedUser())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(r)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").exists());
    }
}
