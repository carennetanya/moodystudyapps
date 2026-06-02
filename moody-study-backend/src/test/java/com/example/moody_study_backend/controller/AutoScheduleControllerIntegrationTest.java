package com.example.moody_study_backend.controller;

import java.util.Map;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;

public class AutoScheduleControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void generateAutoSchedule_success() throws Exception {
        mockMvc.perform(post("/api/schedule/auto")
                        .with(user("test@example.com")
                            .authorities(() -> "ROLE_USER"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("daysAhead", 3))))
                .andExpect(status().isOk());
    }

    @Test
    public void generateAutoSchedule_default_success() throws Exception {
        mockMvc.perform(post("/api/schedule/auto")
                        .with(user("test@example.com")
                            .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }
}
