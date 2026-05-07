package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.dto.AwardLevelUpResponse;
import com.example.moody_study_backend.dto.AwardProgressResponse;
import com.example.moody_study_backend.services.AwardLevelUpService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/award")
@CrossOrigin(origins = "*")
public class AwardLevelUpController {

    private final AwardLevelUpService awardLevelUpService;

    public AwardLevelUpController(AwardLevelUpService awardLevelUpService) {
        this.awardLevelUpService = awardLevelUpService;
    }

    @GetMapping
    public ResponseEntity<List<AwardLevelUpResponse>> listAwards(Authentication authentication) {
        return ResponseEntity.ok(awardLevelUpService.getAwards(authentication.getName()));
    }

    @GetMapping("/progress")
    public ResponseEntity<AwardProgressResponse> getProgress(Authentication authentication) {
        return ResponseEntity.ok(awardLevelUpService.getProgress(authentication.getName()));
    }

    @GetMapping("/eligibility")
    public ResponseEntity<AwardProgressResponse> checkEligibility(Authentication authentication) {
        return ResponseEntity.ok(awardLevelUpService.getProgress(authentication.getName()));
    }

    @PostMapping("/grant")
    public ResponseEntity<AwardLevelUpResponse> grantAward(Authentication authentication) {
        return ResponseEntity.ok(awardLevelUpService.grantAward(authentication.getName()));
    }
}
