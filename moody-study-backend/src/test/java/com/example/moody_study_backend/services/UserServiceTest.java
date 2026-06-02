package com.example.moody_study_backend.services;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.example.moody_study_backend.dto.UpdateAccountRequest;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    UserRepository userRepository;

    @Mock
    PasswordEncoder passwordEncoder;

    @InjectMocks
    UserService userService;

    @Test
    void updateAccount_shouldSaveUpdatedUser() {
        User user = new User();
        user.setPassword("encoded");

        UpdateAccountRequest request = new UpdateAccountRequest();
        request.setCurrentPassword("123456");
        request.setNewEmail("new@gmail.com");
        request.setNewPassword("abcdef");

        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(true);
        when(userRepository.existsByEmail(anyString())).thenReturn(false);

        userService.updateAccount("old@gmail.com", request);

        verify(userRepository).save(user);
    }

    @Test
    void updateAccount_shouldFail_whenUserNotFound() {
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class,
                () -> userService.updateAccount("x@gmail.com", new UpdateAccountRequest()));
    }
}
