package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.BaseIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

public class FileParseControllerIntegrationTest extends BaseIntegrationTest {

    @Test
    public void parseFile_success_txt() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file", "sample.txt", MediaType.TEXT_PLAIN_VALUE, "Matematika\nIPA".getBytes()
        );

        mockMvc.perform(multipart("/api/schedule/parse-file").file(file).with(authenticatedUser()))
                .andExpect(status().isOk());
    }

    @Test
    public void parseFile_badRequest_unsupported() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file", "sample.exe", "application/octet-stream", new byte[]{1,2,3}
        );

        mockMvc.perform(multipart("/api/schedule/parse-file").file(file).with(authenticatedUser()))
                .andExpect(status().isBadRequest());
    }
}
