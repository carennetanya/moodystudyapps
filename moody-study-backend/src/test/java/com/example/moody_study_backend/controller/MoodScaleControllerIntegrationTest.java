package com.example.moody_study_backend.controller;

import java.time.LocalDateTime;
import java.util.Map;

import org.junit.jupiter.api.Test;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;

public class MoodScaleControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void recordMood_success() throws Exception {
        Map<String, Object> body = Map.of(
                "moodType", "study",
                "moodValue", 4,
                "moodFeel", "focused",
                "moodIntensity", 2,
                "moodNote", "Bagus"
        );

        mockMvc.perform(post("/api/mood-scale/record").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk());
    }

    @Test
    public void getUserMoods_success() throws Exception {
        mockMvc.perform(get("/api/mood-scale").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void getMoodsByDateRange_success() throws Exception {
        seedMoodScale();

        mockMvc.perform(get("/api/mood-scale/date-range")
                        .param("startDate", LocalDateTime.now().minusDays(1).toString())
                        .param("endDate", LocalDateTime.now().plusDays(1).toString())
                        .with(user("test@example.com")
                                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void getMoodsByType_success() throws Exception {
        seedMoodScale();

        mockMvc.perform(get("/api/mood-scale/type/study").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }
}
