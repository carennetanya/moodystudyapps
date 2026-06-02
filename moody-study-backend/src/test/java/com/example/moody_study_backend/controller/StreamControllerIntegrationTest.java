package com.example.moody_study_backend.controller;

import java.time.LocalDateTime;
import java.util.Map;

import org.junit.jupiter.api.Test;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;
import com.example.moody_study_backend.entity.Stream;

public class StreamControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void createStream_success() throws Exception {
        Map<String, Object> body = Map.of(
                "streamId", "stream-1",
                "startTime", LocalDateTime.now().toString()
        );

        mockMvc.perform(post("/api/streams/create").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk());
    }

    @Test
    public void getUserStreams_success() throws Exception {
        mockMvc.perform(get("/api/streams").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void updateStreamStatus_success() throws Exception {
        Stream stream = seedStream();
        Map<String, Object> body = Map.of(
                "status", "completed",
                "endTime", LocalDateTime.now().toString()
        );

        mockMvc.perform(put("/api/streams/{streamId}/status", stream.getId())
                        .with(user("test@example.com").authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk());
    }

    @Test
    public void getStream_success() throws Exception {
        Stream stream = seedStream();

        mockMvc.perform(get("/api/streams/{streamId}", stream.getId()).with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }
}
