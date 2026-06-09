package com.example.moody_study_backend.services;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.example.moody_study_backend.dto.NicknameRequest;
import com.example.moody_study_backend.dto.UpdateAvatarRequest;
import com.example.moody_study_backend.dto.UpdateNameRequest;
import com.example.moody_study_backend.dto.UpdateUsernameRequest;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserProfile;
import com.example.moody_study_backend.repository.UserProfileRepository;
import com.example.moody_study_backend.repository.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class UserProfileService {

    private final UserProfileRepository userProfileRepository;
    private final UserRepository userRepository;

    // ── Helper: record a change event in user_profiles ──────────────────────
    private void recordChange(User user, String fieldName, String oldValue, String newValue) {
        UserProfile log = UserProfile.builder()
                .user(user)
                .fieldName(fieldName)
                .oldValue(oldValue)
                .newValue(newValue)
                .changedAt(LocalDateTime.now())
                .build();
        userProfileRepository.save(log);
    }

    // ── Read ─────────────────────────────────────────────────────────────────
    public Map<String, Object> getUserInfo(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("validation.user.notFound"));

        Map<String, Object> info = new HashMap<>();
        info.put("name", user.getName());
        info.put("username", user.getUsername());
        info.put("email", user.getEmail());
        info.put("avatarUrl", user.getAvatarUrl());
        return info;
    }

    // ── Update name ──────────────────────────────────────────────────────────
    public Map<String, String> updateName(String email, UpdateNameRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("validation.user.notFound"));

        String oldName = user.getName();
        user.setName(request.getName());
        userRepository.save(user);

        recordChange(user, "name", oldName, request.getName());

        return Map.of("name", user.getName());
    }

    // ── Update username ──────────────────────────────────────────────────────
    public Map<String, String> updateUsername(String email, UpdateUsernameRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("validation.user.notFound"));

        // Skip duplicate check if username unchanged
        if (!user.getUsername().equals(request.getUsername())
                && userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("validation.username.taken");
        }

        String oldUsername = user.getUsername();
        user.setUsername(request.getUsername());
        userRepository.save(user);

        recordChange(user, "username", oldUsername, request.getUsername());

        return Map.of("username", user.getUsername());
    }

    // ── Update avatar ────────────────────────────────────────────────────────
    public Map<String, String> updateAvatar(String email, UpdateAvatarRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("validation.user.notFound"));

        String oldAvatar = user.getAvatarUrl();
        user.setAvatarUrl(request.getAvatarUrl());
        userRepository.save(user);

        // Don't log the full base64 blob as old_value — just record the event
        recordChange(user, "avatar_url", oldAvatar != null ? "[previous]" : null, "[updated]");

        return Map.of("avatarUrl", user.getAvatarUrl());
    }

    // ── Nickname (stored in user_profiles as latest entry) ──────────────────
    public Map<String, String> setNickname(String email, NicknameRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("validation.user.notFound"));

        String oldNickname = userProfileRepository
                .findFirstByUserAndFieldNameOrderByChangedAtDesc(user, "nickname")
                .map(UserProfile::getNewValue)
                .orElse(user.getName());

        recordChange(user, "nickname", oldNickname, request.getNickname());

        return Map.of("nickname", request.getNickname());
    }

    public Map<String, String> getNickname(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("validation.user.notFound"));

        String nickname = userProfileRepository
                .findFirstByUserAndFieldNameOrderByChangedAtDesc(user, "nickname")
                .map(UserProfile::getNewValue)
                .orElse(user.getName());

        return Map.of("nickname", nickname);
    }

    // ── Check availability (self-excluding) ─────────────────────────────────
    public Map<String, Object> checkEmailAvailable(String authenticatedEmail, String emailToCheck) {
        User user = userRepository.findByEmail(authenticatedEmail)
                .orElseThrow(() -> new RuntimeException("validation.user.notFound"));

        boolean taken = userRepository.existsByEmailIgnoreCaseAndIdNot(emailToCheck, user.getId());
        Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("available", !taken);
        if (taken) body.put("reason", "validation.email.taken");
        return body;
    }

    public Map<String, Object> checkUsernameAvailable(String authenticatedEmail, String usernameToCheck) {
        User user = userRepository.findByEmail(authenticatedEmail)
                .orElseThrow(() -> new RuntimeException("validation.user.notFound"));

        boolean taken = userRepository.existsByUsernameIgnoreCaseAndIdNot(usernameToCheck, user.getId());
        Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("available", !taken);
        if (taken) body.put("reason", "validation.username.taken");
        return body;
    }
}