package com.example.moody_study_backend.services;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.moody_study_backend.entity.Streak;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.AwardLevelUpRepository;
import com.example.moody_study_backend.repository.StreakRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;
import com.example.moody_study_backend.repository.UserXpRepository;

@ExtendWith(MockitoExtension.class)
class StreakServiceTest {

    @Mock
    StreakRepository streakRepository;

    @Mock
    StudySessionRepository studySessionRepository;

    @Mock
    UserRepository userRepository;

    @Mock
    DailyQuestService dailyQuestService;

    @Mock
    UserXpRepository userXpRepository;

    @Mock
    AwardLevelUpRepository awardLevelUpRepository;

    @InjectMocks
    StreakService streakService;

    @Test
    void getStreak_shouldReturnResponse() {
        User user = new User();
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        when(streakRepository.findByUser(user)).thenReturn(Optional.empty());
        when(studySessionRepository.countByUser(user)).thenReturn(0L);
        when(userXpRepository.findByUser(user)).thenReturn(Optional.empty());

        assertNotNull(streakService.getStreak("test@gmail.com"));
    }
}
