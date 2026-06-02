package com.example.moody_study_backend.services;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestTemplate;

import com.example.moody_study_backend.dto.GenerateQuizRequest;
import com.example.moody_study_backend.entity.GeneratedQuiz;
import com.example.moody_study_backend.entity.StudyMaterial;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.GeneratedQuizRepository;
import com.example.moody_study_backend.repository.StudyMaterialRepository;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class GeneratedQuizServiceTest {

    @Mock
    GeneratedQuizRepository generatedQuizRepository;

    @Mock
    StudyMaterialRepository studyMaterialRepository;

    @Mock
    UserRepository userRepository;

    private GeneratedQuizService generatedQuizService;

    @BeforeEach
    void setUp() {
        generatedQuizService = new GeneratedQuizService(
                generatedQuizRepository,
                studyMaterialRepository,
                userRepository,
                new TestGeminiService()
        );
    }

    private static class TestGeminiService extends GeminiService {
        TestGeminiService() {
            super(new RestTemplate());
        }

        @Override
        public String generateQuiz(String materialText, String quizType, String difficulty, int questionCount) {
            return "[]";
        }
    }

    @Test
    void getSavedQuizzes_shouldReturnSavedQuizResponses() {
        User user = new User();
        user.setId(1L);
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));

        StudyMaterial material = StudyMaterial.builder()
                .id(2L)
                .fileName("file.pdf")
                .uploadedAt(LocalDateTime.now())
                .build();

        GeneratedQuiz quiz = GeneratedQuiz.builder()
                .id(1L)
                .user(user)
                .material(material)
                .saved(true)
                .generatedAt(LocalDateTime.now())
                .build();
        when(generatedQuizRepository.findByUserAndSavedTrueOrderByGeneratedAtDesc(user)).thenReturn(List.of(quiz));

        assertEquals(1, generatedQuizService.getSavedQuizzes("test@gmail.com").size());
    }
}
