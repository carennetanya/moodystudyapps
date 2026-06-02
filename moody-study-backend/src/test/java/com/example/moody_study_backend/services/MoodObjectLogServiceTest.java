package com.example.moody_study_backend.services;

import java.util.List;
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

import com.example.moody_study_backend.entity.MoodObjectLog;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.MoodObjectLogRepository;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class MoodObjectLogServiceTest {

    @Mock
    MoodObjectLogRepository moodObjectLogRepository;

    @Mock
    UserRepository userRepository;

    @InjectMocks
    MoodObjectLogService moodObjectLogService;

    @Test
    void createMoodLog_shouldSaveAndReturnLog() {
        User user = new User();
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        when(moodObjectLogRepository.save(any(MoodObjectLog.class))).thenAnswer(invocation -> invocation.getArgument(0));

        MoodObjectLog log = moodObjectLogService.createMoodLog("test@gmail.com", "Math", "Happy", 5, "notes");

        assertEquals("Happy", log.getMoodFeel());
    }
}
