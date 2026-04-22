package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.GeneratedQuiz;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface GeneratedQuizRepository extends JpaRepository<GeneratedQuiz, Long> {
    List<GeneratedQuiz> findByUserOrderByGeneratedAtDesc(User user);
}