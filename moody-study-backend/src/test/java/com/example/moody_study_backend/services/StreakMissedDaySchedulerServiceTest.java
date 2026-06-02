package com.example.moody_study_backend.services;

import java.time.LocalDate;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
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

@ExtendWith(MockitoExtension.class)
class StreakMissedDaySchedulerServiceTest {

    @Mock
    StreakRepository streakRepository;

    @Mock
    StudySessionRepository studySessionRepository;

    @Mock
    AwardLevelUpRepository awardLevelUpRepository;

    @InjectMocks
    StreakMissedDaySchedulerService service;

    @Test
    void decrementLifeForMissedDays_shouldSaveUpdatedStreak() {
        User user = new User();
        user.setEmail("test@gmail.com");
        Streak streak = Streak.builder().user(user).life(2).lastStudyDate(LocalDate.now().minusDays(2)).build();

        when(streakRepository.findByLastStudyDateBeforeAndLifeGreaterThan(any(LocalDate.class), any(Integer.class)))
                .thenReturn(List.of(streak));
        when(streakRepository.save(any(Streak.class))).thenAnswer(invocation -> invocation.getArgument(0));

        service.decrementLifeForMissedDays();

        verify(streakRepository).save(any(Streak.class));
    }
}
