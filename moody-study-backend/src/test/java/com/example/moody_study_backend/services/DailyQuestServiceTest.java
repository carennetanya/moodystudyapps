package com.example.moody_study_backend.services;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.moody_study_backend.dto.DailyQuestResponse;
import com.example.moody_study_backend.entity.DailyQuest;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserXp;
import com.example.moody_study_backend.repository.DailyQuestRepository;
import com.example.moody_study_backend.repository.StudySessionRepository;
import com.example.moody_study_backend.repository.UserRepository;
import com.example.moody_study_backend.repository.UserXpRepository;

@ExtendWith(MockitoExtension.class)
class DailyQuestServiceTest {

    @Mock
    DailyQuestRepository dailyQuestRepository;

    @Mock
    UserXpRepository userXpRepository;

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
