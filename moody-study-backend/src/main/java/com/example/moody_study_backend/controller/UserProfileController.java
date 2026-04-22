package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.dto.NicknameRequest;
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