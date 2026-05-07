package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.Notification;
import com.example.moody_study_backend.entity.Schedule;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    // Ambil semua notif user, belum dibaca dulu
    List<Notification> findByUserOrderByCreatedAtDesc(User user);

    // Cek apakah notif untuk schedule ini sudah pernah dibuat (hindari duplikat)
    boolean existsBySchedule(Schedule schedule);
}