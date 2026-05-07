package com.example.moody_study_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "mood_scales")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MoodScale {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private LocalDateTime moodDate;

    @Column(nullable = false)
    private String moodType; // happy, sad, anxious, focused, tired, etc.

    @Column(nullable = false)
    private int moodValue; // 1-10 scale

    @Column(nullable = false)
    private String moodFeel; // detailed feeling description

    private int moodIntensity; // 1-5 intensity level

    private String moodNote; // optional note

    @Column(nullable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();
}
