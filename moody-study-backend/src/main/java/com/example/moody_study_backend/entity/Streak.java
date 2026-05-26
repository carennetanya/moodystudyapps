package com.example.moody_study_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

@Entity
@Table(name = "streaks")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Streak {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private int currentStreak;

    private LocalDate lastStudyDate;

    // Life System: jumlah nyawa user
    @Column(nullable = false)
    @Builder.Default
    private int life = 3;

    /**
     * Tanggal terakhir life dikurangi oleh scheduler / checkLogin.
     * Dipakai sebagai guard supaya pengurangan nyawa tidak dobel
     * antara StreakMissedDaySchedulerService dan checkLogin.
     */
    private LocalDate lastLifeDeductedDate;
}