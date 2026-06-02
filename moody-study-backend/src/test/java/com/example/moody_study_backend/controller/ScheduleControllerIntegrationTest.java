package com.example.moody_study_backend.controller;

import org.junit.jupiter.api.Test;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;
import com.example.moody_study_backend.dto.ScheduleRequest;

public class ScheduleControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void createSchedule_success() throws Exception {
        ScheduleRequest r = new ScheduleRequest();
        r.setSubject("Matematika");
        r.setStudyDate("2026-06-02");
        r.setStartTime("10:00");
        r.setEndTime("11:00");

        mockMvc.perform(post("/api/schedule").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(r)))
                .andExpect(status().isOk());
    }

    @Test
    public void getSchedules_success() throws Exception {
        mockMvc.perform(get("/api/schedule").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void completeSchedule_notFound_badRequest() throws Exception {
        mockMvc.perform(patch("/api/schedule/999/complete").with(authenticatedUser()))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void deleteSchedule_notFound_badRequest() throws Exception {
        mockMvc.perform(delete("/api/schedule/999").with(authenticatedUser()))
                .andExpect(status().isNoContent());
    }

    @Test
    public void completeSchedule_success() throws Exception {
        Long id = seedSchedule().getId();

        mockMvc.perform(patch("/api/schedule/{id}/complete", id).with(authenticatedUser()))
                .andExpect(status().isOk());
    }

    @Test
    public void deleteSchedule_success() throws Exception {
        Long id = seedSchedule().getId();

        mockMvc.perform(delete("/api/schedule/{id}", id).with(authenticatedUser()))
                .andExpect(status().isNoContent());
    }
}
