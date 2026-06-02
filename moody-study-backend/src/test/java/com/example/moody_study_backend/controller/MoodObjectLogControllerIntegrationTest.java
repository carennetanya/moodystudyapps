package com.example.moody_study_backend.controller;

import java.time.LocalDateTime;
import java.util.Map;

import org.junit.jupiter.api.Test;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;
import com.example.moody_study_backend.entity.MoodObjectLog;

public class MoodObjectLogControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void createLog_success() throws Exception {
        Map<String, Object> body = Map.of(
                "subject", "Matematika",
                "moodFeel", "happy",
                "moodIntensity", 3,
                "notes", "Belajar lancar"
        );

        mockMvc.perform(post("/api/mood-logs/create").with(user("test@example.com")
        .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk());
    }

    @Test
    public void getUserLogs_success() throws Exception {
        mockMvc.perform(get("/api/mood-logs").with(user("test@example.com")
        .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void getLogsBySubject_success() throws Exception {
        seedMoodLog();

        mockMvc.perform(get("/api/mood-logs/subject/Matematika").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void getLogsByDateRange_success() throws Exception {
        seedMoodLog();

        mockMvc.perform(get("/api/mood-logs/date-range")
                        .param("startDate", LocalDateTime.now().minusDays(1).toString())
                        .param("endDate", LocalDateTime.now().plusDays(1).toString())
                        .with(user("test@example.com")
                                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void getLog_success() throws Exception {
        MoodObjectLog log = seedMoodLog();

        mockMvc.perform(get("/api/mood-logs/{logId}", log.getId()).with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }
}
