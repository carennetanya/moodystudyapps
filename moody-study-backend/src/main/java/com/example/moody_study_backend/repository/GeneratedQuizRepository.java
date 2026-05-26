package com.example.moody_study_backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.moody_study_backend.entity.GeneratedQuiz;
import com.example.moody_study_backend.entity.User;

@Repository
public interface GeneratedQuizRepository extends JpaRepository<GeneratedQuiz, Long> {
    List<GeneratedQuiz> findByUserOrderByGeneratedAtDesc(User user);
    List<GeneratedQuiz> findByUserAndSavedTrueOrderByGeneratedAtDesc(User user);
}