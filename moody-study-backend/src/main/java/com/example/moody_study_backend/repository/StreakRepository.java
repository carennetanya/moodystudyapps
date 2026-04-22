package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.Streak;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface StreakRepository extends JpaRepository<Streak, Long> {
    Optional<Streak> findByUser(User user);
}