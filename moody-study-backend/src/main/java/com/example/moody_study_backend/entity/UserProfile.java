package com.example.moody_study_backend.entity;

import jakarta.persistence.*;
import lombok.*;

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

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String nickname;

    // Email user (bisa diakses juga via user.getEmail())
    private String email;

    // Untuk fitur change password
    private String currentPassword;
    private String newPassword;
    private String confirmPassword;
}