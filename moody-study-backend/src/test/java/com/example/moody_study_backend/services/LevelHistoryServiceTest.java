package com.example.moody_study_backend.services;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.moody_study_backend.dto.LevelHistoryResponse;
import com.example.moody_study_backend.entity.AwardLevelUp;
import com.example.moody_study_backend.entity.StudyMaterial;
import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.AwardLevelUpRepository;
import com.example.moody_study_backend.repository.StudyMaterialRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class LevelHistoryServiceTest {

    @Mock
    UserRepository userRepository;

    @Mock
    StudySessionRepository studySessionRepository;

    @Mock
    StudyMaterialRepository studyMaterialRepository;

    @Mock
    AwardLevelUpRepository awardLevelUpRepository;

    @InjectMocks
    LevelHistoryService levelHistoryService;

    @Test
    void getLevelHistory_shouldReturnResponse() {
        User user = new User();
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        StudySession session = StudySession.builder()
                .startTime(LocalDateTime.now())
                .durationMinutes(60)
                .distractionSeconds(15)
                .mood("Focused")
                .location("Home")
                .build();

        when(studySessionRepository.findByUserOrderByStartTimeAsc(user)).thenReturn(List.of(session));
        when(studyMaterialRepository.findByStudySession(session)).thenReturn(List.of());
        when(awardLevelUpRepository.findByUserAndLevel(user, 1)).thenReturn(Optional.empty());

        LevelHistoryResponse response = levelHistoryService.getLevelHistory("test@gmail.com", 1);

        assertNotNull(response);
    }
}
