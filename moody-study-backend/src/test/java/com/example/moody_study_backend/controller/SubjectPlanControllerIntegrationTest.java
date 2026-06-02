package com.example.moody_study_backend.controller;

import java.time.LocalDate;
import java.util.Map;

import org.junit.jupiter.api.Test;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;
import com.example.moody_study_backend.entity.SubjectPlan;

public class SubjectPlanControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void createPlan_success() throws Exception {

        Map<String, Object> body = Map.of(
                "subject", "Fisika",
                "description", "Rencana belajar fisika",
                "startDate", LocalDate.now().toString(),
                "endDate", LocalDate.now().plusDays(7).toString(),
                "targetHours", 10
        );

        mockMvc.perform(post("/api/subject-plans/create")
                        .with(user("test@example.com")
                                .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk());
    }

    @Test
    public void getPlan_notFound_badRequest() throws Exception {

        mockMvc.perform(get("/api/subject-plans/999")
                        .with(user("test@example.com")
                                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void updatePlan_success() throws Exception {
        SubjectPlan plan = seedSubjectPlan();
        Map<String, Object> body = Map.of(
                "completedHours", 2,
                "status", "active"
        );

        mockMvc.perform(put("/api/subject-plans/{planId}", plan.getId())
                        .with(user("test@example.com")
                                .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk());
    }

    @Test
    public void getUserPlans_success() throws Exception {
        seedSubjectPlan();

        mockMvc.perform(get("/api/subject-plans")
                        .with(user("test@example.com")
                                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void getActivePlans_success() throws Exception {
        seedSubjectPlan();

        mockMvc.perform(get("/api/subject-plans/active")
                        .with(user("test@example.com")
                                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void getPlan_success() throws Exception {
        SubjectPlan plan = seedSubjectPlan();

        mockMvc.perform(get("/api/subject-plans/{planId}", plan.getId())
                        .with(user("test@example.com")
                                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }
}
