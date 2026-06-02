package com.example.moody_study_backend.controller;

import org.junit.jupiter.api.Test;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;

public class AwardLevelUpControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void listAwards_success() throws Exception {
        mockMvc.perform(get("/api/award").with(user("test@example.com")
                                                        .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void getProgress_success() throws Exception {
        mockMvc.perform(get("/api/award/progress").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void checkEligibility_success() throws Exception {
        mockMvc.perform(get("/api/award/eligibility").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void grantAward_success() throws Exception {
        for (int i = 0; i < 6; i++) {
            seedStudySession();
        }

        mockMvc.perform(post("/api/award/grant").with(user("test@example.com")
                                                                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }
}
