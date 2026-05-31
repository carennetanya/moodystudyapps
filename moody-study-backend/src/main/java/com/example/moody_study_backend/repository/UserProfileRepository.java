package com.example.moody_study_backend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserProfile;

@Repository
public interface UserProfileRepository extends JpaRepository<UserProfile, Long> {

    // All history entries for a user (ordered newest first)
    List<UserProfile> findByUserOrderByChangedAtDesc(User user);

    // All history for a specific field
    List<UserProfile> findByUserAndFieldNameOrderByChangedAtDesc(User user, String fieldName);

    // Most recent value of a field (for nickname lookup, etc.)
    Optional<UserProfile> findFirstByUserAndFieldNameOrderByChangedAtDesc(User user, String fieldName);
}
