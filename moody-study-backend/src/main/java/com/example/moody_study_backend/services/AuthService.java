package com.example.moody_study_backend.services;

import com.example.moody_study_backend.dto.AuthResponse;
import com.example.moody_study_backend.dto.LoginRequest;
import com.example.moody_study_backend.dto.RegisterRequest;
import com.example.moody_study_backend.dto.UpdateEmailRequest;
import com.example.moody_study_backend.dto.UpdatePasswordRequest;
import com.example.moody_study_backend.entity.Role;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserProfile;
import com.example.moody_study_backend.repository.UserProfileRepository;
import com.example.moody_study_backend.repository.UserRepository;
import com.example.moody_study_backend.security.jwt.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    // ── Helper: record audit log ─────────────────────────────────────────────
    private void recordChange(User user, String fieldName, String oldValue, String newValue) {
        userProfileRepository.save(
            UserProfile.builder()
                .user(user)
                .fieldName(fieldName)
                .oldValue(oldValue)
                .newValue(newValue)
                .changedAt(LocalDateTime.now())
                .build()
        );
    }

    // ── Register ─────────────────────────────────────────────────────────────
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("validation.username.taken");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("validation.email.taken");
        }

        User user = User.builder()
                .username(request.getUsername())
                .name(request.getName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(Role.ROLE_USER)
                .build();

        userRepository.save(user);

        String token = jwtUtil.generateToken(user.getEmail(), user.getRole().name());
        return new AuthResponse(token, user.getName(), user.getEmail(), user.getRole().name());
    }

    // ── Login ─────────────────────────────────────────────────────────────────
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("validation.credentials.invalid"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("validation.credentials.invalid");
        }

        String token = jwtUtil.generateToken(user.getEmail(), user.getRole().name());
        return new AuthResponse(token, user.getName(), user.getEmail(), user.getRole().name());
    }

    // ── Update email — returns NEW token with updated email as subject ────────
    public AuthResponse updateEmail(String currentEmail, UpdateEmailRequest request) {
        User user = userRepository.findByEmail(currentEmail)
                .orElseThrow(() -> new RuntimeException("validation.user.notFound"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("validation.credentials.invalid");
        }

        if (userRepository.existsByEmail(request.getNewEmail())) {
            throw new RuntimeException("validation.email.taken");
        }

        String oldEmail = user.getEmail();
        user.setEmail(request.getNewEmail());
        userRepository.save(user);

        // Record audit log AFTER save so user.id is stable
        recordChange(user, "email", oldEmail, request.getNewEmail());

        // Generate new token with new email as subject
        String newToken = jwtUtil.generateToken(user.getEmail(), user.getRole().name());
        return new AuthResponse(newToken, user.getName(), user.getEmail(), user.getRole().name());
    }

    // ── Update password ───────────────────────────────────────────────────────
    public Map<String, String> updatePassword(String email, UpdatePasswordRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("validation.user.notFound"));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            throw new RuntimeException("validation.credentials.invalid");
        }

        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new RuntimeException("validation.password.mismatch");
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        // Record audit log — never store actual password values
        recordChange(user, "password", "[changed]", "[changed]");

        return Map.of("message", "Password berhasil diubah");
    }
}
