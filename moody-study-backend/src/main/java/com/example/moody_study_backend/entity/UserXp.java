package com.example.moody_study_backend.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Menyimpan total XP yang dimiliki setiap user.
 */
@Entity
@Table(name = "user_xp")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserXp {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false)
    @Builder.Default
    private int totalXp = 0;
}