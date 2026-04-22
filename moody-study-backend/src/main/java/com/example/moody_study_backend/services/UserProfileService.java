package com.example.moody_study_backend.services;

import com.example.moody_study_backend.dto.NicknameRequest;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserProfile;
import com.example.moody_study_backend.repository.UserProfileRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class UserProfileService {

    private final UserProfileRepository userProfileRepository;
    private final UserRepository userRepository;

    public Map<String, String> setNickname(String email, NicknameRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        UserProfile profile = userProfileRepository.findByUser(user)
                .orElse(UserProfile.builder().user(user).build());

        profile.setNickname(request.getNickname());
        userProfileRepository.save(profile);

        return Map.of("nickname", profile.getNickname());
    }

    public Map<String, String> getNickname(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        String nickname = userProfileRepository.findByUser(user)
                .map(UserProfile::getNickname)
                .orElse(user.getName());

        return Map.of("nickname", nickname);
    }
}