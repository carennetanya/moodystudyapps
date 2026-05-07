package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.MoodObjectLog;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface MoodObjectLogRepository extends JpaRepository<MoodObjectLog, Long> {
    List<MoodObjectLog> findByUser(User user);
    List<MoodObjectLog> findByUserAndSubject(User user, String subject);
    List<MoodObjectLog> findByUserAndMoodDateBetween(User user, LocalDateTime startDate, LocalDateTime endDate);
}
