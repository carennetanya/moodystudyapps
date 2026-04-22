package com.example.moody_study_backend.repository;

import com.example.moody_study_backend.entity.SavedFile;
import com.example.moody_study_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SavedFileRepository extends JpaRepository<SavedFile, Long> {
    List<SavedFile> findByUserOrderBySavedAtDesc(User user);
}