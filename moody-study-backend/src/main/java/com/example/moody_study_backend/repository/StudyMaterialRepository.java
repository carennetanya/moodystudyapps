package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.StudyMaterial;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StudyMaterialRepository extends JpaRepository<StudyMaterial, Long> {
    List<StudyMaterial> findByUserOrderByUploadedAtDesc(User user);
}