package com.example.moody_study_backend.services;

import com.example.moody_study_backend.entity.SubjectPlan;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.SubjectPlanRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SubjectPlanService {

    private final SubjectPlanRepository subjectPlanRepository;
    private final UserRepository userRepository;

    public SubjectPlan createSubjectPlan(String email, String subject, String description,
                                         LocalDate startDate, LocalDate endDate, int targetHours) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        SubjectPlan plan = SubjectPlan.builder()
                .user(user)
                .subject(subject)
                .description(description)
                .startDate(startDate)
                .endDate(endDate)
                .status("active")
                .targetHours(targetHours)
                .completedHours(0)
                .build();

        return subjectPlanRepository.save(plan);
    }

    public SubjectPlan updateSubjectPlan(Long planId, int completedHours, String status) {
        SubjectPlan plan = subjectPlanRepository.findById(planId)
                .orElseThrow(() -> new RuntimeException("Subject Plan tidak ditemukan"));

        if (completedHours >= 0) {
            plan.setCompletedHours(completedHours);
        }
        if (status != null) {
            plan.setStatus(status);
        }

        return subjectPlanRepository.save(plan);
    }

    public List<SubjectPlan> getUserPlans(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
        return subjectPlanRepository.findByUser(user);
    }

    public List<SubjectPlan> getActivePlans(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));
        return subjectPlanRepository.findByUserAndStatus(user, "active");
    }

    public SubjectPlan getSubjectPlan(Long planId) {
        return subjectPlanRepository.findById(planId)
                .orElseThrow(() -> new RuntimeException("Subject Plan tidak ditemukan"));
    }
}
