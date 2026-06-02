package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.BaseIntegrationTest;
import org.junit.jupiter.api.Test;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

public class GeneratedQuizControllerDeleteIntegrationTest extends BaseIntegrationTest {

    @Test
    public void deleteQuiz_notFound_badRequest() throws Exception {
        mockMvc.perform(delete("/api/quiz/999").with(authenticatedUser()))
                .andExpect(status().isBadRequest());
    }
}
