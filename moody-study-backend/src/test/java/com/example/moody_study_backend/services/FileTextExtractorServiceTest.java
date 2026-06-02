package com.example.moody_study_backend.services;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.multipart.MultipartFile;

import com.example.moody_study_backend.services.GeminiService;

@ExtendWith(MockitoExtension.class)
class FileTextExtractorServiceTest {

    @Mock
    GeminiService geminiService;

    @InjectMocks
    FileTextExtractorService fileTextExtractorService;

    @Test
    void extractSubjects_shouldUseGeminiResult() throws Exception {
        MultipartFile file = mock(MultipartFile.class);
        when(file.getOriginalFilename()).thenReturn("subjects.txt");
        when(file.getBytes()).thenReturn("Basis Data, Jaringan Komputer".getBytes());
        when(geminiService.extractSubjectsFromText(anyString())).thenReturn(List.of("Basis Data", "Jaringan Komputer"));

        assertEquals(2, fileTextExtractorService.extractSubjects(file).size());
    }
}
