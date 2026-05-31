package com.example.moody_study_backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_profiles")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Many rows per user (each row = one change event)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // Which field was changed: "name", "username", "avatar_url", "email", "password", "nickname"
    @Column(name = "field_name", nullable = false, length = 50)
    private String fieldName;

    // Previous value before change (null if first-time set)
    @Column(name = "old_value", columnDefinition = "TEXT")
    private String oldValue;

    // New value after change
    @Column(name = "new_value", columnDefinition = "TEXT")
    private String newValue;

    @Column(name = "changed_at", nullable = false)
    private LocalDateTime changedAt;

    @PrePersist
    protected void onCreate() {
        if (changedAt == null) {
            changedAt = LocalDateTime.now();
        }
    }
}
