package com.example.moody_study_backend.services;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.example.moody_study_backend.dto.LoginRequest;
import com.example.moody_study_backend.dto.RegisterRequest;
import com.example.moody_study_backend.dto.UpdateEmailRequest;
import com.example.moody_study_backend.dto.UpdatePasswordRequest;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.UserProfileRepository;
import com.example.moody_study_backend.repository.UserRepository;
import com.example.moody_study_backend.security.jwt.JwtUtil;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    UserRepository userRepository;

    @Mock
    UserProfileRepository userProfileRepository;

    @Mock
    PasswordEncoder passwordEncoder;

    @Mock
    JwtUtil jwtUtil;

    @InjectMocks
    AuthService authService;

    @Test
    void register_shouldSaveNewUser() {
        RegisterRequest request = new RegisterRequest();
        request.setEmail("test@gmail.com");
        request.setPassword("123456");

        when(userRepository.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        assertNotNull(authService.register(request));
        verify(userRepository).save(any(User.class));
    }

    @Test
    void login_shouldReturnToken() {
        User user = new User();
        user.setEmail("test@gmail.com");
        user.setPassword("encoded");

        LoginRequest request = new LoginRequest();
        request.setEmail("test@gmail.com");
        request.setPassword("123456");

        when(userRepository.findByEmail(anyString())).thenReturn(Optional.of(user));
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(true);
        when(jwtUtil.generateToken(anyString(), anyString())).thenReturn("jwt-token");

        assertNotNull(authService.login(request));
    }

    @Test
    void updatePassword_shouldFail_whenUserMissing() {
        UpdatePasswordRequest request = new UpdatePasswordRequest();
        request.setCurrentPassword("current");
        request.setNewPassword("newpass");

        when(userRepository.findByEmail(anyString())).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class, () -> authService.updatePassword("missing@gmail.com", request));
    }
}
