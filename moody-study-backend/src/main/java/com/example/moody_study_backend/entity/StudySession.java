package com.example.moody_study_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "study_sessions")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StudySession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    private String mood;
    private String location;
    private int durationMinutes;
    private int focusSeconds;
    private int distractionSeconds;

    @Column(nullable = false)
    private LocalDateTime startTime;

    private LocalDateTime endTime;
}