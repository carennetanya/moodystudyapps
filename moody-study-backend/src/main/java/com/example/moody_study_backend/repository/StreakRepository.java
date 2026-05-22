package com.example.moody_study_backend.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.moody_study_backend.entity.Streak;
import com.example.moody_study_backend.entity.User;

@Repository
public interface StreakRepository extends JpaRepository<Streak, Long> {
    Optional<Streak> findByUser(User user);
    List<Streak> findByLastStudyDateBeforeAndLifeGreaterThan(LocalDate date, int life);
}