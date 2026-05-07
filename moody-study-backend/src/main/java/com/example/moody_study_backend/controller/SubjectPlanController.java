package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.entity.SubjectPlan;
import com.example.moody_study_backend.services.SubjectPlanService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/subject-plans")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class SubjectPlanController {

    private final SubjectPlanService subjectPlanService;

    @PostMapping("/create")
    public ResponseEntity<SubjectPlan> createPlan(
            @RequestBody Map<String, Object> request,
            Authentication authentication) {
        String subject = (String) request.get("subject");
        String description = (String) request.get("description");
        LocalDate startDate = LocalDate.parse((String) request.get("startDate"));
        LocalDate endDate = LocalDate.parse((String) request.get("endDate"));
        int targetHours = ((Number) request.getOrDefault("targetHours", 0)).intValue();
        
        SubjectPlan plan = subjectPlanService.createSubjectPlan(authentication.getName(), subject, 
                                                                description, startDate, endDate, targetHours);
        return ResponseEntity.ok(plan);
    }

    @PutMapping("/{planId}")
    public ResponseEntity<SubjectPlan> updatePlan(
            @PathVariable Long planId,
            @RequestBody Map<String, Object> request) {
        int completedHours = ((Number) request.getOrDefault("completedHours", -1)).intValue();
        String status = (String) request.get("status");
        
        SubjectPlan plan = subjectPlanService.updateSubjectPlan(planId, completedHours, status);
        return ResponseEntity.ok(plan);
    }

    @GetMapping
    public ResponseEntity<List<SubjectPlan>> getUserPlans(Authentication authentication) {
        List<SubjectPlan> plans = subjectPlanService.getUserPlans(authentication.getName());
        return ResponseEntity.ok(plans);
    }

    @GetMapping("/active")
    public ResponseEntity<List<SubjectPlan>> getActivePlans(Authentication authentication) {
        List<SubjectPlan> plans = subjectPlanService.getActivePlans(authentication.getName());
        return ResponseEntity.ok(plans);
    }

    @GetMapping("/{planId}")
    public ResponseEntity<SubjectPlan> getPlan(@PathVariable Long planId) {
        SubjectPlan plan = subjectPlanService.getSubjectPlan(planId);
        return ResponseEntity.ok(plan);
    }
}
