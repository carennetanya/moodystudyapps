package com.example.moody_study_backend.controller;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;
import com.example.moody_study_backend.dto.UpdateAccountRequest;

public class UserControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void getProfile_success() throws Exception {
        mockMvc.perform(get("/api/user/me").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void updateAccount_badRequest_emptyBody() throws Exception {
        mockMvc.perform(patch("/api/user/update").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void updateAccount_success() throws Exception {
        UpdateAccountRequest r = new UpdateAccountRequest();
        r.setCurrentPassword("password123");
        r.setNewEmail("account-updated@example.com");
        r.setNewPassword("newpass123");

        mockMvc.perform(patch("/api/user/update").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(r)))
                .andExpect(status().isOk());
    }
}
