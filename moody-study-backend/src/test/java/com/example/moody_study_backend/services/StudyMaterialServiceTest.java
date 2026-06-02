package com.example.moody_study_backend.services;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestTemplate;

import com.example.moody_study_backend.dto.MaterialRequest;
import com.example.moody_study_backend.entity.StudyMaterial;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.StudyMaterialRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class StudyMaterialServiceTest {

    @Mock
    StudyMaterialRepository studyMaterialRepository;

    @Mock
    UserRepository userRepository;

    @Mock
    StudySessionRepository studySessionRepository;

    private StudyMaterialService studyMaterialService;

    @BeforeEach
    void setUp() {
        studyMaterialService = new StudyMaterialService(
                studyMaterialRepository,
                userRepository,
                studySessionRepository,
                new TestGeminiService()
        );
    }

    private static class TestGeminiService extends GeminiService {
        TestGeminiService() {
            super(new RestTemplate());
        }

        @Override
        public String summarizeMaterial(String originalText, String fileName) {
            return "summary";
        }
    }

    @Test
    void uploadMaterial_shouldSaveMaterial() {
        User user = new User();
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        when(studyMaterialRepository.save(any(StudyMaterial.class))).thenAnswer(invocation -> invocation.getArgument(0));

        MaterialRequest request = new MaterialRequest();
        request.setFileName("file.pdf");
        request.setOriginalText("hello");

        assertNotNull(studyMaterialService.uploadMaterial("test@gmail.com", request));
    }

    @Test
    void getMaterials_shouldReturnList() {
        User user = new User();
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        when(studyMaterialRepository.findByUserOrderByUploadedAtDesc(user)).thenReturn(List.of(
                StudyMaterial.builder()
                        .id(1L)
                        .fileName("file.pdf")
                        .uploadedAt(java.time.LocalDateTime.now())
                        .build()
        ));

        assertEquals(1, studyMaterialService.getMaterials("test@gmail.com").size());
    }
}
