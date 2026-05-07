package com.example.moody_study_backend.controller;

import com.example.moody_study_backend.entity.Notification;
import com.example.moody_study_backend.entity.User;
import com.example.moody_study_backend.repository.NotificationRepository;
import com.example.moody_study_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class NotificationController {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    // Frontend polling endpoint — ambil semua notif milik user
    @GetMapping
    public ResponseEntity<List<Notification>> getNotifications(Authentication authentication) {
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        List<Notification> notifs = notificationRepository.findByUserOrderByCreatedAtDesc(user);
        return ResponseEntity.ok(notifs);
    }

    // Tandai satu notif sebagai sudah dibaca
    @PatchMapping("/{id}/read")
    public ResponseEntity<Map<String, String>> markAsRead(@PathVariable Long id) {
        Notification notif = notificationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Notifikasi tidak ditemukan"));

        notif.setRead(true);
        notificationRepository.save(notif);

        return ResponseEntity.ok(Map.of("message", "Notifikasi ditandai sudah dibaca"));
    }

    // Tandai semua notif user sebagai sudah dibaca
    @PatchMapping("/read-all")
    public ResponseEntity<Map<String, String>> markAllAsRead(Authentication authentication) {
        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User tidak ditemukan"));

        List<Notification> notifs = notificationRepository.findByUserOrderByCreatedAtDesc(user);
        notifs.forEach(n -> n.setRead(true));
        notificationRepository.saveAll(notifs);

        return ResponseEntity.ok(Map.of("message", "Semua notifikasi ditandai sudah dibaca"));
    }
}