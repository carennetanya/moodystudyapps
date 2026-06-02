package com.example.moody_study_backend.controller;

import org.junit.jupiter.api.Test;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;
import com.example.moody_study_backend.dto.GenerateQuizRequest;
import com.example.moody_study_backend.entity.GeneratedQuiz;
import com.example.moody_study_backend.entity.StudyMaterial;

public class GeneratedQuizControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void getQuizzes_success_empty() throws Exception {
        mockMvc.perform(get("/api/quiz").with(user("test@example.com")
                                                        .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void generateQuiz_badRequest_missingMaterial() throws Exception {
        GenerateQuizRequest r = new GenerateQuizRequest();
        mockMvc.perform(post("/api/quiz/generate").with(user("test@example.com")
                                                                    .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(r)))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void generateQuiz_success() throws Exception {
        StudyMaterial material = seedStudyMaterial();
        GenerateQuizRequest r = new GenerateQuizRequest();
        r.setMaterialId(material.getId());
        r.setQuizType("multiple_choice");
        r.setDifficulty("easy");
        r.setQuestionCount(1);

        mockMvc.perform(post("/api/quiz/generate").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(r)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.materialId").value(material.getId()));
    }

    @Test
    public void getSavedQuizzes_success() throws Exception {
        seedGeneratedQuiz(true);

        mockMvc.perform(get("/api/quiz/saved").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void getQuizById_success() throws Exception {
        GeneratedQuiz quiz = seedGeneratedQuiz(false);

        mockMvc.perform(get("/api/quiz/{id}", quiz.getId()).with(user("test@example.com")
                        .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(quiz.getId()));
    }

    @Test
    public void toggleSave_success() throws Exception {
        GeneratedQuiz quiz = seedGeneratedQuiz(false);

        mockMvc.perform(post("/api/quiz/{id}/save", quiz.getId()).with(user("test@example.com")
                        .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.saved").value(true));
    }

    @Test
    public void deleteQuiz_success() throws Exception {
        GeneratedQuiz quiz = seedGeneratedQuiz(false);

        mockMvc.perform(delete("/api/quiz/{id}", quiz.getId()).with(user("test@example.com")
                        .authorities(() -> "ROLE_USER")))
                .andExpect(status().isNoContent());
    }
}
