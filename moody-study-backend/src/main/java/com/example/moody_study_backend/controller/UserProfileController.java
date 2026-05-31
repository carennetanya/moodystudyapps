package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.dto.NicknameRequest;
import com.example.moody_study_backend.dto.UpdateNameRequest;
import com.example.moody_study_backend.dto.UpdateUsernameRequest;
import com.example.moody_study_backend.dto.UpdateAvatarRequest;
import com.example.moody_study_backend.services.UserProfileService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/profile")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UserProfileController {

    private final UserProfileService userProfileService;

    @GetMapping("/info")
    public ResponseEntity<Map<String, Object>> getUserInfo(Authentication authentication) {
        return ResponseEntity.ok(
                userProfileService.getUserInfo(authentication.getName())
        );
    }

    @PostMapping("/update-name")
    public ResponseEntity<Map<String, String>> updateName(
            @Valid @RequestBody UpdateNameRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(
                userProfileService.updateName(authentication.getName(), request)
        );
    }

    @PostMapping("/update-username")
    public ResponseEntity<Map<String, String>> updateUsername(
            @Valid @RequestBody UpdateUsernameRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(
                userProfileService.updateUsername(authentication.getName(), request)
        );
    }

    @PostMapping("/update-avatar")
    public ResponseEntity<Map<String, String>> updateAvatar(
            @Valid @RequestBody UpdateAvatarRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(
                userProfileService.updateAvatar(authentication.getName(), request)
        );
    }

    @PostMapping("/nickname")
    public ResponseEntity<Map<String, String>> setNickname(
            @Valid @RequestBody NicknameRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(
                userProfileService.setNickname(authentication.getName(), request)
        );
    }

    @GetMapping("/nickname")
    public ResponseEntity<Map<String, String>> getNickname(Authentication authentication) {
        return ResponseEntity.ok(
                userProfileService.getNickname(authentication.getName())
        );
    }
}