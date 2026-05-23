package com.example.moody_study_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;

/**
 * Menyimpan 3 quest yang dipilih secara random untuk user pada hari tertentu,
 * beserta status penyelesaiannya.
 */
@Entity
@Table(name = "daily_quests",
       uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "quest_date", "quest_key"}))
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyQuest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** Tanggal quest ini berlaku (format: yyyy-MM-dd). */
    @Column(nullable = false)
    private LocalDate questDate;

    /**
     * Identifier quest dari pool (misal: "FIRST_SESSION", "ZERO_DISTRACTION", dsb).
     * Lihat QuestKey enum.
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private QuestKey questKey;

    /** Sudah diselesaikan user hari ini? */
    @Column(nullable = false)
    @Builder.Default
    private boolean completed = false;

    /** XP yang diberikan saat quest selesai. */
    @Column(nullable = false)
    private int xpReward;
}