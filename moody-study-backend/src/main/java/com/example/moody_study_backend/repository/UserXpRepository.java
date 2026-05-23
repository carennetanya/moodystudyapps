package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserXp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserXpRepository extends JpaRepository<UserXp, Long> {
    Optional<UserXp> findByUser(User user);
}