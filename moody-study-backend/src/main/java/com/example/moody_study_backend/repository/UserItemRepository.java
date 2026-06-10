package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.entity.UserItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserItemRepository extends JpaRepository<UserItem, Long> {
    List<UserItem> findByUserOrderByPurchasedAtDesc(User user);
    Optional<UserItem> findByUserAndItemId(User user, String itemId);
    boolean existsByUserAndItemId(User user, String itemId);
}