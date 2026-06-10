package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserCoin;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserCoinRepository extends JpaRepository<UserCoin, Long> {
    Optional<UserCoin> findByUser(User user);
}