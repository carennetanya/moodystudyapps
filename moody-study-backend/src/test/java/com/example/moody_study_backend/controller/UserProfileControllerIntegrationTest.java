package com.example.moody_study_backend.controller;

import java.util.Map;

import org.junit.jupiter.api.Test;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;

public class UserProfileControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void getUserInfo_success() throws Exception {
        mockMvc.perform(get("/api/profile/info").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void updateName_badRequest_missingFields() throws Exception {
        mockMvc.perform(post("/api/profile/update-name").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void updateName_success() throws Exception {
        mockMvc.perform(post("/api/profile/update-name").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(Map.of("name", "Updated Name"))))
                .andExpect(status().isOk());
    }

    @Test
    public void updateUsername_success() throws Exception {
        mockMvc.perform(post("/api/profile/update-username").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(Map.of("username", "updateduser"))))
                .andExpect(status().isOk());
    }

    @Test
    public void updateAvatar_success() throws Exception {
        mockMvc.perform(post("/api/profile/update-avatar").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(Map.of("avatarUrl", "https://example.com/avatar.png"))))
                .andExpect(status().isOk());
    }

    @Test
    public void setNickname_success() throws Exception {
        mockMvc.perform(post("/api/profile/nickname").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(Map.of("nickname", "Oddy"))))
                .andExpect(status().isOk());
    }

    @Test
    public void getNickname_success() throws Exception {
        mockMvc.perform(get("/api/profile/nickname").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }
}
