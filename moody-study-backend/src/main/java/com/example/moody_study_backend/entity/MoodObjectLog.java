package com.example.moody_study_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "mood_object_logs")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MoodObjectLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne
    @JoinColumn(name = "mood_scale_id")
    private MoodScale moodScale;

    private String subject;

    @Column(nullable = false)
    private String moodFeel;

    private int moodIntensity; // 1-5 scale

    @Column(nullable = false)
    private LocalDateTime moodDate;

    private String notes;

    @Column(nullable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();
}
