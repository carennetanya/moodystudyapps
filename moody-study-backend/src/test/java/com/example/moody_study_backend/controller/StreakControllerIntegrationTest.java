package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.BaseIntegrationTest;
import com.example.moody_study_backend.dto.StudySessionRequest;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

public class StreakControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void getStreak_success() throws Exception {
        mockMvc.perform(get("/api/streak").with(authenticatedUser()))
                .andExpect(status().isOk());
    }

    @Test
    public void checkLogin_success() throws Exception {
        mockMvc.perform(post("/api/streak/check-login").with(authenticatedUser()))
                .andExpect(status().isOk());
    }

    @Test
    public void getLevelHistory_success() throws Exception {
        seedStudySession();

        mockMvc.perform(get("/api/streak/level-history/1").with(authenticatedUser()))
                .andExpect(status().isOk());
    }

    @Test
    public void completeSession_success() throws Exception {
        StudySessionRequest r = new StudySessionRequest();
        r.setMood("focused");
        r.setLocation("Perpustakaan");
        r.setDurationMinutes(45);
        r.setFocusSeconds(2400);
        r.setDistractionSeconds(300);

        mockMvc.perform(post("/api/streak/complete")
                        .with(authenticatedUser())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(r)))
                .andExpect(status().isOk());
    }
}
