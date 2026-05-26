package com.example.moody_study_backend.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.moody_study_backend.entity.StudyMaterial;
import com.example.moody_study_backend.entity.StudySession;
import com.example.moody_study_backend.entity.User;

@Repository
public interface StudyMaterialRepository extends JpaRepository<StudyMaterial, Long> {
    List<StudyMaterial> findByUserOrderByUploadedAtDesc(User user);

    // Ambil semua file yang diupload dalam satu sesi tertentu
    List<StudyMaterial> findByStudySession(StudySession studySession);

    @Query("SELECT COUNT(sm) FROM StudyMaterial sm WHERE sm.user = :user AND sm.summary IS NOT NULL AND TRIM(sm.summary) <> ''")
    long countCompletedSummariesByUser(@Param("user") User user);
}