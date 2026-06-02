package com.example.moody_study_backend.controller;

import org.junit.jupiter.api.Test;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;

public class UserXpControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void getTotalXp_success() throws Exception {
        mockMvc.perform(get("/api/user/xp").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }
}
