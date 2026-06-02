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

import com.example.moody_study_backend.entity.MoodScale;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.MoodScaleRepository;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class MoodScaleServiceTest {

    @Mock
    MoodScaleRepository moodScaleRepository;

    @Mock
    UserRepository userRepository;

    @InjectMocks
    MoodScaleService moodScaleService;

    @Test
    void recordMood_shouldPersistMoodScale() {
        User user = new User();
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        when(moodScaleRepository.save(any(MoodScale.class))).thenAnswer(invocation -> invocation.getArgument(0));

        MoodScale moodScale = moodScaleService.recordMood("test@gmail.com", "happy", 5, "good", 3, "note");

        assertEquals(5, moodScale.getMoodValue());
    }
}
