package com.example.moody_study_backend.services;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.moody_study_backend.entity.Stream;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.StreamRepository;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class StreamServiceTest {

    @Mock
    StreamRepository streamRepository;

    @Mock
    UserRepository userRepository;

    @InjectMocks
    StreamService streamService;

    @Test
    void createStream_shouldPersistStream() {
        User user = new User();
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        when(streamRepository.save(any(Stream.class))).thenAnswer(invocation -> invocation.getArgument(0));

        assertNotNull(streamService.createStream("test@gmail.com", "stream-1", LocalDateTime.now()));
    }
}
