package com.example.moody_study_backend.services;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class StatServiceTest {

    @Mock
    StudySessionRepository studySessionRepository;

    @Mock
    UserRepository userRepository;

    @InjectMocks
    StatService statService;

    @Test
    void getStats_shouldReturnMetricsMap() {
        User user = new User();
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));

        StudySession session = new StudySession();
        session.setDurationMinutes(60);
        session.setFocusSeconds(1200);
        session.setDistractionSeconds(300);
        session.setMood("Happy");
        session.setLocation("Home");
        session.setStartTime(LocalDateTime.now());

        when(studySessionRepository.findByUserOrderByStartTimeDesc(user)).thenReturn(List.of(session));
        when(studySessionRepository.findByUserAndStartTimeBetweenOrderByStartTimeAsc(any(User.class), any(LocalDateTime.class), any(LocalDateTime.class))).thenReturn(List.of(session));
        when(studySessionRepository.countByUserAndStartTimeBetween(any(User.class), any(LocalDateTime.class), any(LocalDateTime.class))).thenReturn(1L);

        Map<String, Object> stats = statService.getStats("test@gmail.com");
        assertEquals(1, stats.get("totalSessions"));
    }
}
