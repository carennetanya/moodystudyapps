package com.example.moody_study_backend.controller;

import java.util.Map;

import org.junit.jupiter.api.Test;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.example.moody_study_backend.BaseIntegrationTest;

public class SavedFileControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void saveFile_success() throws Exception {
        Map<String, String> body = Map.of(
                "fileName", "notes.txt",
                "fileType", "txt",
                "content", "isi file"
        );

        mockMvc.perform(post("/api/files/save").with(user("test@example.com")
                        .authorities(() -> "ROLE_USER"))
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk());
    }

    @Test
    public void getFiles_success() throws Exception {
        mockMvc.perform(get("/api/files").with(user("test@example.com")
                .authorities(() -> "ROLE_USER")))
                .andExpect(status().isOk());
    }

    @Test
    public void deleteFile_notFound_noContentOrBadRequest() throws Exception {
        mockMvc.perform(delete("/api/files/999").with(authenticatedUser()))
                .andExpect(status().isNoContent());
    }

    @Test
    public void deleteFile_success() throws Exception {
        Long id = seedSavedFile().getId();

        mockMvc.perform(delete("/api/files/{id}", id).with(authenticatedUser()))
                .andExpect(status().isNoContent());
    }

    @Test
    public void renameFile_success() throws Exception {
        Long id = seedSavedFile().getId();
        Map<String, String> body = Map.of("newFileName", "renamed.txt");

        mockMvc.perform(patch("/api/files/{id}/rename", id).with(authenticatedUser())
                        .contentType("application/json")
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk());
    }
}
