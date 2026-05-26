package com.example.moody_study_backend.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;

@Repository
public interface StudySessionRepository extends JpaRepository<StudySession, Long> {
    List<StudySession> findByUserOrderByStartTimeDesc(User user);

    List<StudySession> findByUserOrderByStartTimeAsc(User user); // untuk level history

    long countByUserAndStartTimeBetween(User user, LocalDateTime start, LocalDateTime end);

    long countByUser(User user);

    List<StudySession> findByUserAndStartTimeBetweenOrderByStartTimeAsc(
            User user, LocalDateTime start, LocalDateTime end);
}