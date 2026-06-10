package com.example.moody_study_backend.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Menyimpan total Coin yang dimiliki setiap user.
 * Coin didapat dari menyelesaikan Daily Quest dan bisa digunakan di Shop.
 */
@Entity
@Table(name = "user_coins")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserCoin {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false)
    @Builder.Default
    private int totalCoins = 0;
}