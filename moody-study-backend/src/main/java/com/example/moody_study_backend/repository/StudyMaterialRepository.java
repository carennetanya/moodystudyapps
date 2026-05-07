package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.StudyMaterial;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StudyMaterialRepository extends JpaRepository<StudyMaterial, Long> {
    List<StudyMaterial> findByUserOrderByUploadedAtDesc(User user);

    @Query("SELECT COUNT(sm) FROM StudyMaterial sm WHERE sm.user = :user AND sm.summary IS NOT NULL AND TRIM(sm.summary) <> ''")
    long countCompletedSummariesByUser(@Param("user") User user);
}