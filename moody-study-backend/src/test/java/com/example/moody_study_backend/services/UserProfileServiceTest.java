package com.example.moody_study_backend.services;

import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.example.moody_study_backend.dto.UpdateNameRequest;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.UserProfileRepository;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class UserProfileServiceTest {

    @Mock
    UserProfileRepository userProfileRepository;

    @Mock
    UserRepository userRepository;

    @InjectMocks
    UserProfileService userProfileService;

    @Test
    void getUserInfo_shouldReturnUserMap() {
        User user = new User();
        user.setName("Test User");
        user.setUsername("testuser");
        user.setEmail("test@gmail.com");
        user.setAvatarUrl("avatar.png");

        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));

        Map<String, Object> info = userProfileService.getUserInfo("test@gmail.com");
        assertEquals("Test User", info.get("name"));
    }
}
