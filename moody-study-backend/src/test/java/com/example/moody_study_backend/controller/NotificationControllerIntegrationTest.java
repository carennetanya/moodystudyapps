package com.example.moody_study_backend.controller;

import org.junit.jupiter.api.Test;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;

public class NotificationControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void getNotifications_success() throws Exception {
        mockMvc.perform(get("/api/notifications").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void markAsRead_notFound_returnsBadRequest() throws Exception {
        mockMvc.perform(patch("/api/notifications/999/read").with(authenticatedUser()))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void markAsRead_success() throws Exception {
        Long id = seedNotification().getId();

        mockMvc.perform(patch("/api/notifications/{id}/read", id).with(authenticatedUser()))
                .andExpect(status().isOk());
    }

    @Test
    public void markAllAsRead_success() throws Exception {
        seedNotification();

        mockMvc.perform(patch("/api/notifications/read-all").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }
}
