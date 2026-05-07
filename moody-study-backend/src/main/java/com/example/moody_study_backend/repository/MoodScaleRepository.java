package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.MoodScale;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface MoodScaleRepository extends JpaRepository<MoodScale, Long> {
    List<MoodScale> findByUser(User user);
    List<MoodScale> findByUserAndMoodDateBetween(User user, LocalDateTime startDate, LocalDateTime endDate);
    List<MoodScale> findByUserAndMoodType(User user, String moodType);
}
