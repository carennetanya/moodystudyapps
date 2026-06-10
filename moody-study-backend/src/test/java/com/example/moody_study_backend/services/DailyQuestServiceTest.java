package com.example.moody_study_backend.services;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.moody_study_backend.dto.DailyQuestResponse;
import com.example.moody_study_backend.entity.DailyQuest;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.DailyQuestRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserCoinRepository;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class DailyQuestServiceTest {

    @Mock
    DailyQuestRepository dailyQuestRepository;

    @Mock
    UserCoinRepository userCoinRepository;

    @Mock
    UserRepository userRepository;

    @Mock
    StudySessionRepository studySessionRepository;

    @InjectMocks
    DailyQuestService dailyQuestService;

    @Test
    void getDailyQuests_shouldGenerateIfMissing() {
        User user = new User();
        user.setId(1L);
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        when(dailyQuestRepository.findByUserAndQuestDate(any(User.class), any(LocalDate.class)))
                .thenReturn(List.of());
        when(dailyQuestRepository.save(any(DailyQuest.class))).thenAnswer(invocation -> invocation.getArgument(0));

        DailyQuestResponse response = dailyQuestService.getDailyQuests("test@gmail.com");

        assertNotNull(response);
        assertEquals(3, response.getQuests().size());
        verify(dailyQuestRepository, times(3)).save(any(DailyQuest.class));
    }
}
