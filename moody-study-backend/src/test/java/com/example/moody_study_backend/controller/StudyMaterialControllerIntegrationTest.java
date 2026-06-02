package com.example.moody_study_backend.controller;

import org.junit.jupiter.api.Test;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;
import com.example.moody_study_backend.dto.MaterialRequest;
import com.example.moody_study_backend.entity.StudyMaterial;

public class StudyMaterialControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void uploadMaterial_success() throws Exception {
        MaterialRequest r = new MaterialRequest();
        r.setFileName("notes.pdf");
        r.setOriginalText("Ini adalah materi belajar.");

        mockMvc.perform(post("/api/material/upload").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(r)))
                .andExpect(status().isOk());
    }

    @Test
    public void getMaterials_success() throws Exception {
        mockMvc.perform(get("/api/material").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void getMaterialById_success() throws Exception {
        StudyMaterial material = seedStudyMaterial();

        mockMvc.perform(get("/api/material/{id}", material.getId()).with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }
}
