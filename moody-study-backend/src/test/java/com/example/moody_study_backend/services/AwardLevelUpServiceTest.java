package com.example.moody_study_backend.services;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.moody_study_backend.entity.AwardLevelUp;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.AwardLevelUpRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class AwardLevelUpServiceTest {

    @Mock
    AwardLevelUpRepository awardLevelUpRepository;

    @Mock
    StudySessionRepository studySessionRepository;

    @Mock
    UserRepository userRepository;

    @InjectMocks
    AwardLevelUpService awardLevelUpService;

    @Test
    void getAwards_shouldReturnAwardList() {
        User user = new User();
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));

        AwardLevelUp award = new AwardLevelUp();
        award.setLevel(1);
        award.setSummaryCountThreshold(6);
        award.setXpPoints(50);
        when(awardLevelUpRepository.findByUserOrderByLevelAsc(user)).thenReturn(List.of(award));

        assertEquals(1, awardLevelUpService.getAwards("test@gmail.com").size());
    }
}
