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
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

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
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        String oldName = user.getName();
        user.setName(request.getName());
        userRepository.save(user);

        recordChange(user, "name", oldName, request.getName());

        return Map.of("name", user.getName());
    }

    // ── Update username ──────────────────────────────────────────────────────
    public Map<String, String> updateUsername(String email, UpdateUsernameRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        // Skip duplicate check if username unchanged
        if (!user.getUsername().equals(request.getUsername())
                && userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("Username sudah digunakan");
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
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

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
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        String oldNickname = userProfileRepository
                .findFirstByUserAndFieldNameOrderByChangedAtDesc(user, "nickname")
                .map(UserProfile::getNewValue)
                .orElse(user.getName());

        recordChange(user, "nickname", oldNickname, request.getNickname());

        return Map.of("nickname", request.getNickname());
    }

    public Map<String, String> getNickname(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        String nickname = userProfileRepository
                .findFirstByUserAndFieldNameOrderByChangedAtDesc(user, "nickname")
                .map(UserProfile::getNewValue)
                .orElse(user.getName());

        return Map.of("nickname", nickname);
    }
}