package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.SubjectPlan;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SubjectPlanRepository extends JpaRepository<SubjectPlan, Long> {
    List<SubjectPlan> findByUser(User user);
    List<SubjectPlan> findByUserAndStatus(User user, String status);
    List<SubjectPlan> findByUserAndSubject(User user, String subject);
}
