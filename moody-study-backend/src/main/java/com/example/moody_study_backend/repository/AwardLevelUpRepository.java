package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.AwardLevelUp;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AwardLevelUpRepository extends JpaRepository<AwardLevelUp, Long> {
    List<AwardLevelUp> findByUserOrderByLevelAsc(User user);
    Optional<AwardLevelUp> findByUserAndLevel(User user, int level);
}
