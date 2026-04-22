package com.example.moody_study_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "saved_files")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SavedFile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    private String fileName;
    private String fileType;

    @Column(columnDefinition = "TEXT")
    private String content;

    private LocalDateTime savedAt;
}