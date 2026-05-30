package com.example.moody_study_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "study_materials")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StudyMaterial {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // Relasi optional ke sesi belajar — null kalau upload di luar sesi
    @ManyToOne
    @JoinColumn(name = "session_id", nullable = true)
    private StudySession studySession;

    private String title;

    private String fileName;

    @Column(columnDefinition = "TEXT")
    private String originalText;

    @Column(columnDefinition = "TEXT")
    private String summary;

    private LocalDateTime uploadedAt;
}