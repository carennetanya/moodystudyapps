package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface StudySessionRepository extends JpaRepository<StudySession, Long> {
    List<StudySession> findByUserOrderByStartTimeDesc(User user);

    long countByUserAndStartTimeBetween(User user, LocalDateTime start, LocalDateTime end);

    // Untuk statistik 7 hari terakhir
    List<StudySession> findByUserAndStartTimeBetweenOrderByStartTimeAsc(
            User user, LocalDateTime start, LocalDateTime end);
}